//
//  FileLoader.swift
//  VideoPlayer
//
//  Created by sparisot on 08/09/2020.
//  Copyright © 2020 Stéphane Parisot. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import Accelerate  /* Audio meter: https://stackoverflow.com/questions/51706314/extract-meter-levels-from-audio-file */


class FileLoader {
    
    var fileURL: URL
    var outputArray : [Float] = []
    var samples : [Int] = []
    var delegate : FileLoaderDelegate?
    
    let noiseFloor: Float = -50.0

    
    init(url:URL) {
        self.fileURL = url
    }
    
    func loadSample() {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            //Start the computation for samples asynchronously by submitting it to the default background queue
            
            AudioContext.load(fromAudioURL: self.fileURL) { audioContext in
                
                
                guard let audioContext = audioContext else {
                    fatalError("Couldn't create the audioContext")
                }
                self.outputArray = self.render(audioContext: audioContext, targetSamples: targetSamples)
                
                // OutputArray est le tableau des échantillons en db compris entre -50 et 0
                // On convertit OutputArray en samples qui sera compris entre 0 et containerHeight (200 en général)
                // int$0 - noiseFloor (généralement -50) * (containerHeight / noiseFloor)
                self.samples = self.outputArray.map { (Int($0 - self.noiseFloor)) * Int(containerHeight) / Int(-self.noiseFloor) }
     
                DispatchQueue.main.async {
                    //Tell the delegate that the work is done

                    self.didLoadSample()
                }
            }
  
        }
    }
    
    func didLoadSample() {
        delegate?.didFinishLoading(self)
    }
    
}

//MARK: - Process Audio Samples /* ----------------------------   */
extension FileLoader {

    func render(audioContext: AudioContext?, targetSamples: Int) -> [Float]{
        guard let audioContext = audioContext else {
            fatalError("Couldn't create the audioContext")
        }
        
        let sampleRange: CountableRange<Int> = 0..<audioContext.totalSamples
        
        guard let reader = try? AVAssetReader(asset: audioContext.asset)
            else {
                fatalError("Couldn't initialize the AVAssetReader")
        }
        
        reader.timeRange = CMTimeRange(start: CMTime(value: Int64(sampleRange.lowerBound), timescale: audioContext.asset.duration.timescale),
                                       duration: CMTime(value: Int64(sampleRange.count), timescale: audioContext.asset.duration.timescale))
        
        
        let outputSettingsDict: [String : Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
        
        let readerOutput = AVAssetReaderTrackOutput(track: audioContext.assetTrack,
                                                    outputSettings: outputSettingsDict)
        readerOutput.alwaysCopiesSampleData = false
        reader.add(readerOutput)
        
        var channelCount = 1
        let formatDescriptions = audioContext.assetTrack.formatDescriptions as! [CMAudioFormatDescription]
        for item in formatDescriptions {
            guard let fmtDesc = CMAudioFormatDescriptionGetStreamBasicDescription(item) else {
                fatalError("Couldn't get the format description")
            }
            channelCount = Int(fmtDesc.pointee.mChannelsPerFrame)
        }
        
        let samplesPerPixel = max(1, channelCount * sampleRange.count / targetSamples)
        let filter = [Float](repeating: 1.0 / Float(samplesPerPixel), count: samplesPerPixel)
        
        var outputSamples = [Float]()
        var sampleBuffer = Data()
        
        // 16-bit samples
        reader.startReading()
        defer { reader.cancelReading() }
        
        while reader.status == .reading {
            guard let readSampleBuffer = readerOutput.copyNextSampleBuffer(),
                let readBuffer = CMSampleBufferGetDataBuffer(readSampleBuffer) else {
                    break
            }
            // Append audio sample buffer into our current sample buffer
            var readBufferLength = 0
            var readBufferPointer: UnsafeMutablePointer<Int8>?
            CMBlockBufferGetDataPointer(readBuffer,
                                        atOffset: 0,
                                        lengthAtOffsetOut: &readBufferLength,
                                        totalLengthOut: nil,
                                        dataPointerOut: &readBufferPointer)
            sampleBuffer.append(UnsafeBufferPointer(start: readBufferPointer, count: readBufferLength))
            CMSampleBufferInvalidate(readSampleBuffer)
            
            let totalSamples = sampleBuffer.count / MemoryLayout<Int16>.size
            let downSampledLength = totalSamples / samplesPerPixel
            let samplesToProcess = downSampledLength * samplesPerPixel
            
            guard samplesToProcess > 0 else { continue }
            
            processSamples(fromData: &sampleBuffer,
                           outputSamples: &outputSamples,
                           samplesToProcess: samplesToProcess,
                           downSampledLength: downSampledLength,
                           samplesPerPixel: samplesPerPixel,
                           filter: filter)
        }
        
        // Process the remaining samples at the end which didn't fit into samplesPerPixel
        let samplesToProcess = sampleBuffer.count / MemoryLayout<Int16>.size
        if samplesToProcess > 0 {
            let downSampledLength = 1
            let samplesPerPixel = samplesToProcess
            let filter = [Float](repeating: 1.0 / Float(samplesPerPixel), count: samplesPerPixel)
            
            processSamples(fromData: &sampleBuffer,
                           outputSamples: &outputSamples,
                           samplesToProcess: samplesToProcess,
                           downSampledLength: downSampledLength,
                           samplesPerPixel: samplesPerPixel,
                           filter: filter)
        }
        
        // if (reader.status == AVAssetReaderStatusFailed || reader.status == AVAssetReaderStatusUnknown)
        guard reader.status == .completed else {
            fatalError("Couldn't read the audio file")
        }


        return outputSamples
    }

    func processSamples(fromData sampleBuffer: inout Data,
                        outputSamples: inout [Float],
                        samplesToProcess: Int,
                        downSampledLength: Int,
                        samplesPerPixel: Int,
                        filter: [Float]) {
        
        sampleBuffer.withUnsafeBytes { (samples: UnsafeRawBufferPointer) in
            var processingBuffer = [Float](repeating: 0.0, count: samplesToProcess)
            
            let sampleCount = vDSP_Length(samplesToProcess)
            
            //Create an UnsafePointer<Int16> from samples
            let unsafeBufferPointer = samples.bindMemory(to: Int16.self)
            let unsafePointer = unsafeBufferPointer.baseAddress!
            
            //Convert 16bit int samples to floats
            vDSP_vflt16(unsafePointer, 1, &processingBuffer, 1, sampleCount)
            
            //Take the absolute values to get amplitude
            vDSP_vabs(processingBuffer, 1, &processingBuffer, 1, sampleCount)
            
            //get the corresponding dB, and clip the results
            getdB(from: &processingBuffer)
            
            //Downsample and average
            var downSampledData = [Float](repeating: 0.0, count: downSampledLength)
            vDSP_desamp(processingBuffer,
                        vDSP_Stride(samplesPerPixel),
                        filter, &downSampledData,
                        vDSP_Length(downSampledLength),
                        vDSP_Length(samplesPerPixel))
            
            //Remove processed samples
            sampleBuffer.removeFirst(samplesToProcess * MemoryLayout<Int16>.size)
            
            outputSamples += downSampledData
        }
    }

    func getdB(from normalizedSamples: inout [Float]) {
        // Convert samples to a log scale
        var zero: Float = 32768.0
        vDSP_vdbcon(normalizedSamples, 1, &zero, &normalizedSamples, 1, vDSP_Length(normalizedSamples.count), 1)
        
        //Clip to [noiseFloor, 0]
        var ceil: Float = 0.0
        var noiseFloorMutable = noiseFloor
        vDSP_vclip(normalizedSamples, 1, &noiseFloorMutable, &ceil, &normalizedSamples, 1, vDSP_Length(normalizedSamples.count))
    }
    



}
