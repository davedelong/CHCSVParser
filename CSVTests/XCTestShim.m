//
//  XCTestShim.m
//  CSV
//
//  Created by Dave DeLong on 4/10/17.
//
//

#import <objc/runtime.h>
#import "XCTestShim.h"

@implementation XCTestCase (Shim)

- (instancetype)initWithCategory:(NSString *)categoryName testName:(NSString *)name block:(void(^)(void))testBlock {
    Class categoryClass = objc_getClass(categoryName.UTF8String);
    if (categoryClass == NULL) {
        categoryClass = objc_allocateClassPair([XCTestCase class], categoryName.UTF8String, 0);
        objc_registerClassPair(categoryClass);
    }
    
    SEL testSelector = sel_registerName([NSString stringWithFormat:@"test%@", name].UTF8String);
    Method existingMethod = class_getInstanceMethod(categoryClass, testSelector);
    
    if (existingMethod != NULL) {
        NSAssert(NO, @"A method already exists with the name %@", name);
    }
    
    IMP testIMP = imp_implementationWithBlock(^(id _self){ testBlock(); });
    class_addMethod(categoryClass, testSelector, testIMP, "v@:");
    
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[NSMethodSignature signatureWithObjCTypes:"v@:"]];
    [invocation setSelector:testSelector];
    
    return [[categoryClass alloc] initWithInvocation:invocation];
}

@end
