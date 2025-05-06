/*
     File: MYAudioTapProcessor.m
 Abstract: Audio tap processor using MTAudioProcessingTap for audio visualization and processing.
  Version: 1.0.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import "MYAudioTapProcessor.h"
#import <AVFoundation/AVFoundation.h>

typedef struct AVAudioTapProcessorContext {
	Boolean supportedTapProcessingFormat;
	Boolean isNonInterleaved;
	Float64 sampleRate;
	AudioUnit audioUnit;
	Float64 sampleCount;
	__unsafe_unretained MYAudioTapProcessor *processor;
} AVAudioTapProcessorContext;

static void tap_InitCallback(MTAudioProcessingTapRef tap, void *clientInfo, void **tapStorageOut);
static void tap_FinalizeCallback(MTAudioProcessingTapRef tap);
static void tap_PrepareCallback(MTAudioProcessingTapRef tap, CMItemCount maxFrames, const AudioStreamBasicDescription *processingFormat);
static void tap_UnprepareCallback(MTAudioProcessingTapRef tap);
static void tap_ProcessCallback(MTAudioProcessingTapRef tap, CMItemCount numberFrames, MTAudioProcessingTapFlags flags, AudioBufferList *bufferListInOut, CMItemCount *numberFramesOut, MTAudioProcessingTapFlags *flagsOut);

// Audio Unit callbacks.
static OSStatus AU_RenderCallback(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData);

@interface MYAudioTapProcessor () {
	AVAudioMix *_audioMix;
}

@end

@implementation MYAudioTapProcessor

- (id)initWithAudioAssetTrack:(AVAssetTrack *)audioAssetTrack {
	NSParameterAssert(audioAssetTrack && [audioAssetTrack.mediaType isEqualToString:AVMediaTypeAudio]);
	
	self = [super init];
	
	if (self) {
		_audioAssetTrack = audioAssetTrack;
	}
	
	return self;
}

#pragma mark - Properties

- (AVAudioMix *)audioMix {
	if (!_audioMix) {
		AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
		
		if (audioMix) {
			AVMutableAudioMixInputParameters *audioMixInputParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:self.audioAssetTrack];
			
			if (audioMixInputParameters) {
				MTAudioProcessingTapCallbacks callbacks;
				
				callbacks.version = kMTAudioProcessingTapCallbacksVersion_0;
				callbacks.clientInfo = (__bridge void *)self;
				callbacks.init = tap_InitCallback;
				callbacks.finalize = tap_FinalizeCallback;
				callbacks.prepare = tap_PrepareCallback;
				callbacks.unprepare = tap_UnprepareCallback;
				callbacks.process = tap_ProcessCallback;
				
				MTAudioProcessingTapRef audioProcessingTap;
				if (noErr == MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PreEffects, &audioProcessingTap)) {
					audioMixInputParameters.audioTapProcessor = audioProcessingTap;
					CFRelease(audioProcessingTap);
					audioMix.inputParameters = @[audioMixInputParameters];
					_audioMix = audioMix;
				}
			}
		}
	}
	
	return _audioMix;
}

- (void)setEqualizerValue:(float)value forBand:(NSInteger)bandTag {
	AVAudioMix *audioMix = self.audioMix;
	
	if (audioMix) {
		MTAudioProcessingTapRef audioProcessingTap = ((AVMutableAudioMixInputParameters *)audioMix.inputParameters[0]).audioTapProcessor;
		AVAudioTapProcessorContext *context = (AVAudioTapProcessorContext *)MTAudioProcessingTapGetStorage(audioProcessingTap);
		AudioUnit audioUnit = context->audioUnit;
		
		if (audioUnit) {
			NSArray *array = @[ @32.0f , @64.0f, @125.0f, @250.0f, @500.0f, @1000.0f, @2000.0f, @4000.0f, @8000.0f, @16000.0f ];
			unsigned int i = (unsigned int)bandTag;
			OSStatus status = noErr;
			status = AudioUnitSetParameter(audioUnit, kAUNBandEQParam_FilterType + i, kAudioUnitScope_Global, 0, kAUNBandEQFilterType_Parametric, 0);
			
			status = AudioUnitSetParameter(audioUnit, kAUNBandEQParam_Frequency + i, kAudioUnitScope_Global, 0, [array[i] floatValue], 0);
			
			status = AudioUnitSetParameter(audioUnit, kAUNBandEQParam_Bandwidth + i, kAudioUnitScope_Global, 0, 0.5, 0);
			
			status = AudioUnitSetParameter(audioUnit, kAUNBandEQParam_Gain + i, kAudioUnitScope_Global, 0, value, 0);
			
			status = AudioUnitSetParameter(audioUnit, kAUNBandEQParam_BypassBand + i, kAudioUnitScope_Global, 0, 0, 0);
		}
	}
}

- (void)setListEQ:(NSArray *)listEQ {
	_listEQ = listEQ;
	
	AVAudioMix *audioMix = self.audioMix;
	if (audioMix) {
		MTAudioProcessingTapRef audioProcessingTap = ((AVMutableAudioMixInputParameters *)audioMix.inputParameters[0]).audioTapProcessor;
		AVAudioTapProcessorContext *context = (AVAudioTapProcessorContext *)MTAudioProcessingTapGetStorage(audioProcessingTap);
		AudioUnit audioUnit = context->audioUnit;
		
		if (audioUnit) {
			NSArray *array = @[ @32.0f , @64.0f, @125.0f, @250.0f, @500.0f, @1000.0f, @2000.0f, @4000.0f, @8000.0f, @16000.0f ];
			OSStatus status = noErr;
			UInt32 numBands = 10;
			status = AudioUnitSetProperty(audioUnit, kAUNBandEQProperty_NumberOfBands, kAudioUnitScope_Global, 0, &numBands, sizeof(numBands));
			
			for (int i = 0; i < listEQ.count; i++) {
				NSNumber *number = listEQ[i];
				status = AudioUnitSetParameter(audioUnit, kAUNBandEQParam_FilterType + i, kAudioUnitScope_Global, 0, kAUNBandEQFilterType_Parametric, 0);
				
				status = AudioUnitSetParameter(audioUnit, kAUNBandEQParam_Frequency + i, kAudioUnitScope_Global, 0, [array[i] floatValue], 0);
				
				status = AudioUnitSetParameter(audioUnit, kAUNBandEQParam_Bandwidth + i, kAudioUnitScope_Global, 0, 0.5, 0);
				
				status = AudioUnitSetParameter(audioUnit, kAUNBandEQParam_Gain + i, kAudioUnitScope_Global, 0, [number floatValue], 0);
				
				status = AudioUnitSetParameter(audioUnit, kAUNBandEQParam_BypassBand + i, kAudioUnitScope_Global, 0, 0, 0);
			}
		}
	}
}

@end

#pragma mark - MTAudioProcessingTap Callbacks

static void tap_InitCallback(MTAudioProcessingTapRef tap, void *clientInfo, void **tapStorageOut) {
	MYAudioTapProcessor *processor = (__bridge MYAudioTapProcessor *)clientInfo;
	AVAudioTapProcessorContext *context = calloc(1, sizeof(AVAudioTapProcessorContext));
	context->supportedTapProcessingFormat = false;
	context->isNonInterleaved = false;
	context->sampleRate = NAN;
	context->audioUnit = NULL;
	context->sampleCount = 0.0f;
	context->processor = processor;
	
	*tapStorageOut = context;
}

static void tap_FinalizeCallback(MTAudioProcessingTapRef tap) {
	AVAudioTapProcessorContext *context = (AVAudioTapProcessorContext *)MTAudioProcessingTapGetStorage(tap);
	free(context);
}

static void tap_PrepareCallback(MTAudioProcessingTapRef tap, CMItemCount maxFrames, const AudioStreamBasicDescription *processingFormat) {
	AVAudioTapProcessorContext *context = (AVAudioTapProcessorContext *)MTAudioProcessingTapGetStorage(tap);
	
	// Store sample rate for -setCenterFrequency:.
	context->sampleRate = processingFormat->mSampleRate;
	
	/* Verify processing format (this is not needed for Audio Unit, but for RMS calculation). */
	
	context->supportedTapProcessingFormat = true;
	
	if (processingFormat->mFormatID != kAudioFormatLinearPCM) {
		NSLog(@"Unsupported audio format ID for audioProcessingTap. LinearPCM only.");
		context->supportedTapProcessingFormat = false;
	}
	
	if (!(processingFormat->mFormatFlags & kAudioFormatFlagIsFloat)) {
		NSLog(@"Unsupported audio format flag for audioProcessingTap. Float only.");
		context->supportedTapProcessingFormat = false;
	}
	
	if (processingFormat->mFormatFlags & kAudioFormatFlagIsNonInterleaved) {
		context->isNonInterleaved = true;
	}
	
	/* Create bandpass filter Audio Unit */
	
	AudioUnit audioUnit;
	
	AudioComponentDescription audioComponentDescription;
	audioComponentDescription.componentType = kAudioUnitType_Effect;
	audioComponentDescription.componentSubType = kAudioUnitSubType_NBandEQ;
	audioComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	audioComponentDescription.componentFlags = 0;
	audioComponentDescription.componentFlagsMask = 0;
	
	AudioComponent audioComponent = AudioComponentFindNext(NULL, &audioComponentDescription);
	
	if (audioComponent) {
		if (noErr == AudioComponentInstanceNew(audioComponent, &audioUnit)) {
			OSStatus status = noErr;
			
			// Set audio unit input/output stream format to processing format.
			if (noErr == status) {
				status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, processingFormat, sizeof(AudioStreamBasicDescription));
			}
			
			if (noErr == status) {
				status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, processingFormat, sizeof(AudioStreamBasicDescription));
			}
			
			// Set audio unit render callback.
			if (noErr == status) {
				AURenderCallbackStruct renderCallbackStruct;
				renderCallbackStruct.inputProc = AU_RenderCallback;
				renderCallbackStruct.inputProcRefCon = (void *)tap;
				status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &renderCallbackStruct, sizeof(AURenderCallbackStruct));
			}
			
			// Set audio unit maximum frames per slice to max frames.
			if (noErr == status) {
				long maximumFramesPerSlice = maxFrames;
				status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maximumFramesPerSlice, (UInt32)sizeof(UInt32));
			}
			
			// Initialize audio unit.
			if (noErr == status) {
				status = AudioUnitInitialize(audioUnit);
			}
			
			if (noErr != status) {
				AudioComponentInstanceDispose(audioUnit);
				audioUnit = NULL;
			}
			
			context->audioUnit = audioUnit;
		}
	}
}

static void tap_UnprepareCallback(MTAudioProcessingTapRef tap) {
	AVAudioTapProcessorContext *context = (AVAudioTapProcessorContext *)MTAudioProcessingTapGetStorage(tap);
	
	if (context->audioUnit) {
		AudioUnitUninitialize(context->audioUnit);
		AudioComponentInstanceDispose(context->audioUnit);
		context->audioUnit = NULL;
	}
}

static void tap_ProcessCallback(MTAudioProcessingTapRef tap, CMItemCount numberFrames, MTAudioProcessingTapFlags flags, AudioBufferList *bufferListInOut, CMItemCount *numberFramesOut, MTAudioProcessingTapFlags *flagsOut) {
	AVAudioTapProcessorContext *context = (AVAudioTapProcessorContext *)MTAudioProcessingTapGetStorage(tap);
	
	OSStatus status;
	
	// Skip processing when format not supported.
	if (!context->supportedTapProcessingFormat) {
		NSLog(@"Unsupported tap processing format.");
		return;
	}
	
	MYAudioTapProcessor *processor = context->processor;
	
	if ([processor isEnableEQ]) {
		AudioUnit audioUnit = context->audioUnit;
		
		if (audioUnit) {
			AudioTimeStamp audioTimeStamp;
			audioTimeStamp.mSampleTime = context->sampleCount;
			audioTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
			
			status = AudioUnitRender(audioUnit, 0, &audioTimeStamp, 0, (UInt32)numberFrames, bufferListInOut);
			if (noErr != status) {
				NSLog(@"AudioUnitRender(): %d", (int)status);
				return;
			}
			
			// Increment sample count for audio unit.
			context->sampleCount += numberFrames;
			
			// Set number of frames out.
			*numberFramesOut = numberFrames;
		}
	} else {
		status = MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, NULL, numberFramesOut);
		
		if (noErr != status) {
			NSLog(@"MTAudioProcessingTapGetSourceAudio: %d", (int)status);
			return;
		}
	}
}

#pragma mark - Audio Unit Callbacks

OSStatus AU_RenderCallback(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {
	return MTAudioProcessingTapGetSourceAudio(inRefCon, inNumberFrames, ioData, NULL, NULL, NULL);
}
