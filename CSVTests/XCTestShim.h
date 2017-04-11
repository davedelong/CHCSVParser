//
//  XCTestShim.h
//  CSV
//
//  Created by Dave DeLong on 4/10/17.
//
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

@interface XCTestCase (Shim)

- (instancetype)initWithCategory:(NSString *)categoryName testName:(NSString *)name block:(void(^)(void))testBlock;

@end

NS_ASSUME_NONNULL_END
