/*
	Copyright (C) 2013-2017 DeSmuME team

	This file is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 2 of the License, or
	(at your option) any later version.

	This file is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with the this software.  If not, see <http://www.gnu.org/licenses/>.
 */

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#include <pthread.h>
#include <libkern/OSAtomic.h>
#include <map>

#import "cocoa_util.h"
#include "../../GPU.h"

#ifdef BOOL
#undef BOOL
#endif

#if defined(MAC_OS_X_VERSION_10_11) && (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_11)
#define ENABLE_APPLE_METAL
#endif

#define VIDEO_FLUSH_TIME_LIMIT_OFFSET	8	// The amount of time, in seconds, to wait for a flush to occur on a given CVDisplayLink before stopping it.

class GPUEventHandlerOSX;

typedef std::map<CGDirectDisplayID, CVDisplayLinkRef> DisplayLinksActiveMap;
typedef std::map<CGDirectDisplayID, int64_t> DisplayLinkFlushTimeLimitMap;

@interface MacClientSharedObject : CocoaDSThread
{
	GPUClientFetchObject *GPUFetchObject;
	pthread_rwlock_t *_rwlockFramebuffer[2];
	pthread_mutex_t *_mutexOutputList;
	pthread_mutex_t _mutexFlushVideo;
	NSMutableArray *_cdsOutputList;
	volatile int32_t numberViewsUsingDirectToCPUFiltering;
	
	DisplayLinksActiveMap _displayLinksActiveList;
	DisplayLinkFlushTimeLimitMap _displayLinkFlushTimeList;
}

@property (assign, nonatomic) GPUClientFetchObject *GPUFetchObject;
@property (readonly, nonatomic) volatile int32_t numberViewsUsingDirectToCPUFiltering;

- (const NDSDisplayInfo &) fetchDisplayInfoForIndex:(const u8)bufferIndex;
- (pthread_rwlock_t *) rwlockFramebufferAtIndex:(const u8)bufferIndex;
- (void) setOutputList:(NSMutableArray *)theOutputList mutex:(pthread_mutex_t *)theMutex;
- (void) incrementViewsUsingDirectToCPUFiltering;
- (void) decrementViewsUsingDirectToCPUFiltering;
- (void) handleFetchFromBufferIndexAndPushVideo:(NSData *)indexData;
- (void) pushVideoDataToAllDisplayViews;
- (void) finishAllDisplayViewsAtIndex:(const u8)bufferIndex;
- (void) flushAllDisplaysOnDisplayLink:(CVDisplayLinkRef)displayLink timeStamp:(const CVTimeStamp *)timeStamp;

- (BOOL) isDisplayLinkRunningUsingID:(CGDirectDisplayID)displayID;
- (void) displayLinkStartUsingID:(CGDirectDisplayID)displayID;
- (void) displayLinkListUpdate;

@end

@interface CocoaDSGPU : NSObject
{
	UInt32 gpuStateFlags;
	uint8_t _gpuScale;
	BOOL isCPUCoreCountAuto;
	BOOL _needRestoreFrameLock;
	BOOL _needRestoreRender3DLock;
	
	OSSpinLock spinlockGpuState;
	GPUEventHandlerOSX *gpuEvent;
	GPUClientFetchObject *fetchObject;
}

@property (assign) UInt32 gpuStateFlags;
@property (assign) NSSize gpuDimensions;
@property (assign) NSUInteger gpuScale;
@property (assign) NSUInteger gpuColorFormat;
@property (readonly) pthread_rwlock_t *gpuFrameRWLock;
@property (readonly, nonatomic) GPUClientFetchObject *fetchObject;
@property (readonly, nonatomic) MacClientSharedObject *sharedData;

@property (assign) BOOL layerMainGPU;
@property (assign) BOOL layerMainBG0;
@property (assign) BOOL layerMainBG1;
@property (assign) BOOL layerMainBG2;
@property (assign) BOOL layerMainBG3;
@property (assign) BOOL layerMainOBJ;
@property (assign) BOOL layerSubGPU;
@property (assign) BOOL layerSubBG0;
@property (assign) BOOL layerSubBG1;
@property (assign) BOOL layerSubBG2;
@property (assign) BOOL layerSubBG3;
@property (assign) BOOL layerSubOBJ;

@property (assign) NSInteger render3DRenderingEngine;
@property (assign) BOOL render3DHighPrecisionColorInterpolation;
@property (assign) BOOL render3DEdgeMarking;
@property (assign) BOOL render3DFog;
@property (assign) BOOL render3DTextures;
@property (assign) NSUInteger render3DThreads;
@property (assign) BOOL render3DLineHack;
@property (assign) BOOL render3DMultisample;
@property (assign) BOOL render3DTextureDeposterize;
@property (assign) BOOL render3DTextureSmoothing;
@property (assign) NSUInteger render3DTextureScalingFactor;
@property (assign) BOOL render3DFragmentSamplingHack;

- (void) setOutputList:(NSMutableArray *)theOutputList mutexPtr:(pthread_mutex_t *)theMutex;
- (BOOL) gpuStateByBit:(const UInt32)stateBit;
- (NSString *) render3DRenderingEngineString;
- (void) clearWithColor:(const uint16_t)colorBGRA5551;
- (void) respondToPauseState:(BOOL)isPaused;

@end

#ifdef __cplusplus
extern "C"
{
#endif

CVReturn MacDisplayLinkCallback(CVDisplayLinkRef displayLink,
								const CVTimeStamp *inNow,
								const CVTimeStamp *inOutputTime,
								CVOptionFlags flagsIn,
								CVOptionFlags *flagsOut,
								void *displayLinkContext);

bool OSXOpenGLRendererInit();
bool OSXOpenGLRendererBegin();
void OSXOpenGLRendererEnd();
bool OSXOpenGLRendererFramebufferDidResize(size_t w, size_t h);

bool CreateOpenGLRenderer();
void DestroyOpenGLRenderer();
void RequestOpenGLRenderer_3_2(bool request_3_2);
void SetOpenGLRendererFunctions(bool (*initFunction)(),
								bool (*beginOGLFunction)(),
								void (*endOGLFunction)(),
								bool (*resizeOGLFunction)(size_t w, size_t h));

#ifdef __cplusplus
}
#endif
