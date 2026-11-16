#include <stdint.h>
#import <Foundation/Foundation.h>
#import <objc/message.h>
#import "youtube_player_darwin.h"

#if !__has_feature(objc_arc)
#error "This file must be compiled with ARC enabled"
#endif

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

typedef struct {
  int64_t version;
  void* (*newWaiter)(void);
  void (*awaitWaiter)(void*);
  void* (*currentIsolate)(void);
  void (*enterIsolate)(void*);
  void (*exitIsolate)(void);
  int64_t (*getMainPortId)(void);
  bool (*getCurrentThreadOwnsIsolate)(int64_t);
  void (*invokeListenerPortBlock)(int64_t port, void*);
  void (*invokeBlockingPortBlock)(int64_t port, void*, void*);
} DOBJC_Context;

id objc_retainBlock(id);

#define BLOCKING_BLOCK_IMPL(ctx, TYPE, SIG, INVOKE_DIRECT, INVOKE_LISTENER)    \
  assert(ctx->version >= 1);                                                   \
  void* targetIsolate = ctx->currentIsolate();                                 \
  int64_t targetPort = ctx->getMainPortId == NULL ? 0 : ctx->getMainPortId();  \
  __block __weak TYPE weakSelfBlock = nil;                                     \
  TYPE strongSelfBlock = [SIG {                                                \
    void* currentIsolate = ctx->currentIsolate();                              \
    bool mayEnterIsolate =                                                     \
        currentIsolate == NULL &&                                              \
        ctx->getCurrentThreadOwnsIsolate != NULL &&                            \
        ctx->getCurrentThreadOwnsIsolate(targetPort);                          \
    if (currentIsolate == targetIsolate || mayEnterIsolate) {                  \
      if (mayEnterIsolate) {                                                   \
        ctx->enterIsolate(targetIsolate);                                      \
      }                                                                        \
      INVOKE_DIRECT;                                                           \
      if (mayEnterIsolate) {                                                   \
        ctx->exitIsolate();                                                    \
      }                                                                        \
    } else {                                                                   \
      void* waiter = ctx->newWaiter();                                         \
      TYPE selfRetain = [weakSelfBlock copy];                                  \
      INVOKE_LISTENER;                                                         \
      ctx->awaitWaiter(waiter);                                                \
      (void)selfRetain;                                                        \
    }                                                                          \
  } copy];                                                                     \
  weakSelfBlock = strongSelfBlock;                                             \
  return strongSelfBlock;


__attribute__((visibility("default")))
@interface _a8spcv_BlockArgs_924x5v : NSObject
@property (copy) id block;
@property void * arg0;
@property int64_t arg1;
@property (strong) id arg2;
@property (strong) id arg3;
@end
@implementation _a8spcv_BlockArgs_924x5v
@end

typedef void  (^_ListenerTrampoline)(void * arg0, int64_t arg1, id arg2, id arg3);
__attribute__((visibility("default"))) __attribute__((used))
_ListenerTrampoline _a8spcv_wrapListenerBlock_924x5v(
    int64_t port, DOBJC_Context* ctx) NS_RETURNS_RETAINED {
  __block __weak _ListenerTrampoline weakSelfBlock = nil;
  _ListenerTrampoline strongSelfBlock = [^void(void * arg0, int64_t arg1, id arg2, id arg3) {
    @autoreleasepool {
      _a8spcv_BlockArgs_924x5v* args = [[_a8spcv_BlockArgs_924x5v alloc] init];
      args.block = weakSelfBlock;
      args.arg0 = arg0;
      args.arg1 = arg1;
      args.arg2 = arg2;
      args.arg3 = arg3;
      ctx->invokeListenerPortBlock(port, (__bridge_retained void*)args);
    }
  } copy];
  weakSelfBlock = strongSelfBlock;
  return strongSelfBlock;
}

typedef void  (^_BlockingTrampoline)(void * waiter, void * arg0, int64_t arg1, id arg2, id arg3);
__attribute__((visibility("default"))) __attribute__((used))
_ListenerTrampoline _a8spcv_wrapBlockingBlock_924x5v(int64_t port, DOBJC_Context* ctx,
    void (*directInvoke)(void*)) NS_RETURNS_RETAINED {
  BLOCKING_BLOCK_IMPL(ctx, _ListenerTrampoline, ^void(void * arg0, int64_t arg1, id arg2, id arg3), {
    @autoreleasepool {
      _a8spcv_BlockArgs_924x5v* args = [[_a8spcv_BlockArgs_924x5v alloc] init];
      args.block = weakSelfBlock;
      args.arg0 = arg0;
      args.arg1 = arg1;
      args.arg2 = arg2;
      args.arg3 = arg3;
      directInvoke((__bridge_retained void*)args);
    }
  }, {
    @autoreleasepool {
      _a8spcv_BlockArgs_924x5v* args = [[_a8spcv_BlockArgs_924x5v alloc] init];
      args.block = weakSelfBlock;
      args.arg0 = arg0;
      args.arg1 = arg1;
      args.arg2 = arg2;
      args.arg3 = arg3;
      ctx->invokeBlockingPortBlock(port, (__bridge_retained void*)args, waiter);
    }
  });
}

typedef void  (^_ProtocolTrampoline)(void * sel, int64_t arg1, id arg2, id arg3);
__attribute__((visibility("default"))) __attribute__((used))
void  _a8spcv_protocolTrampoline_924x5v(id target, void * sel, int64_t arg1, id arg2, id arg3) {
  return ((_ProtocolTrampoline)((id (*)(id, SEL, SEL))objc_msgSend)(target, @selector(getDOBJCDartProtocolMethodForSelector:), sel))(sel, arg1, arg2, arg3);
}

__attribute__((visibility("default")))
@interface _a8spcv_BlockArgs_u2w295 : NSObject
@property (copy) id block;
@property void * arg0;
@property int64_t arg1;
@property BOOL arg2;
@property (strong) id arg3;
@end
@implementation _a8spcv_BlockArgs_u2w295
@end

typedef void  (^_ListenerTrampoline_1)(void * arg0, int64_t arg1, BOOL arg2, id arg3);
__attribute__((visibility("default"))) __attribute__((used))
_ListenerTrampoline_1 _a8spcv_wrapListenerBlock_u2w295(
    int64_t port, DOBJC_Context* ctx) NS_RETURNS_RETAINED {
  __block __weak _ListenerTrampoline_1 weakSelfBlock = nil;
  _ListenerTrampoline_1 strongSelfBlock = [^void(void * arg0, int64_t arg1, BOOL arg2, id arg3) {
    @autoreleasepool {
      _a8spcv_BlockArgs_u2w295* args = [[_a8spcv_BlockArgs_u2w295 alloc] init];
      args.block = weakSelfBlock;
      args.arg0 = arg0;
      args.arg1 = arg1;
      args.arg2 = arg2;
      args.arg3 = arg3;
      ctx->invokeListenerPortBlock(port, (__bridge_retained void*)args);
    }
  } copy];
  weakSelfBlock = strongSelfBlock;
  return strongSelfBlock;
}

typedef void  (^_BlockingTrampoline_1)(void * waiter, void * arg0, int64_t arg1, BOOL arg2, id arg3);
__attribute__((visibility("default"))) __attribute__((used))
_ListenerTrampoline_1 _a8spcv_wrapBlockingBlock_u2w295(int64_t port, DOBJC_Context* ctx,
    void (*directInvoke)(void*)) NS_RETURNS_RETAINED {
  BLOCKING_BLOCK_IMPL(ctx, _ListenerTrampoline_1, ^void(void * arg0, int64_t arg1, BOOL arg2, id arg3), {
    @autoreleasepool {
      _a8spcv_BlockArgs_u2w295* args = [[_a8spcv_BlockArgs_u2w295 alloc] init];
      args.block = weakSelfBlock;
      args.arg0 = arg0;
      args.arg1 = arg1;
      args.arg2 = arg2;
      args.arg3 = arg3;
      directInvoke((__bridge_retained void*)args);
    }
  }, {
    @autoreleasepool {
      _a8spcv_BlockArgs_u2w295* args = [[_a8spcv_BlockArgs_u2w295 alloc] init];
      args.block = weakSelfBlock;
      args.arg0 = arg0;
      args.arg1 = arg1;
      args.arg2 = arg2;
      args.arg3 = arg3;
      ctx->invokeBlockingPortBlock(port, (__bridge_retained void*)args, waiter);
    }
  });
}

typedef void  (^_ProtocolTrampoline_1)(void * sel, int64_t arg1, BOOL arg2, id arg3);
__attribute__((visibility("default"))) __attribute__((used))
void  _a8spcv_protocolTrampoline_u2w295(id target, void * sel, int64_t arg1, BOOL arg2, id arg3) {
  return ((_ProtocolTrampoline_1)((id (*)(id, SEL, SEL))objc_msgSend)(target, @selector(getDOBJCDartProtocolMethodForSelector:), sel))(sel, arg1, arg2, arg3);
}

__attribute__((visibility("default"))) __attribute__((used))
Protocol* _a8spcv_YoutubeFlutterApiBridge(void) { return @protocol(YoutubeFlutterApiBridge); }
#undef BLOCKING_BLOCK_IMPL

#pragma clang diagnostic pop
