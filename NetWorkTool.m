//
//  NetWorkTool.m
//  App_OC
//
//  Created by Dafiger on 16/8/19.
//  Copyright © 2016年 wpf. All rights reserved.
//

#import "NetWorkTool.h"

@implementation NetWorkTool

#pragma mark - 获取单例
+ (NetWorkTool *)instanceTool
{
    static NetWorkTool *sharedManagerInstance = nil;
    static dispatch_once_t predicate = 0;
    dispatch_once( &predicate, ^{
        sharedManagerInstance = [[self alloc] init];
    });
    return sharedManagerInstance;
}

#pragma mark - post请求
- (void)req_PostWithUrlStr:(NSString *)urlStr
                  paramDic:(NSDictionary *)paramDic
                   success:(void(^)(id response, BOOL verify))success
                   failure:(void(^)(id error))failure
              showProgress:(BOOL)isShowProgress
{
    NSMutableString *req_str = [NSMutableString string];
    NSArray *keyAry = [paramDic allKeys];
    for (int i=0; i<keyAry.count; i++) {
        NSString *keyStr = keyAry[i];
        [req_str appendString:[NSString stringWithFormat:@"%@=%@", keyStr, [paramDic objectForKey:keyStr]]];
        if (i != keyAry.count - 1) {
            [req_str appendString:@"&"];
        }
    }
    
    NSURL *url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    // 请求超时的时间
    // [request setTimeoutInterval:8.0f];
    // NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:8.0f];
    // 请求方式
    [request setHTTPMethod:@"POST"];
    // 请求报文
    NSData *bodyData = [req_str dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    [request setValue:[NSString stringWithFormat:@"%ld",bodyData.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:bodyData];
    // 设置Cookies
    [request setHTTPShouldHandleCookies:FALSE];
    
//    [request setCachePolicy:NSURLRequestUseProtocolCachePolicy];
//    NSURLRequestUseProtocolCachePolicy       // 默认的缓存策略（取决于协议）
//    NSURLRequestReloadIgnoringLocalCacheData // 忽略缓存，重新请求
//    NSURLRequestReturnCacheDataElseLoad      // 有缓存就用缓存，没有缓存就重新请求
//    NSURLRequestReturnCacheDataDontLoad      // 有缓存就用缓存，没有缓存就不发请求，当做请求出错处理（用于离线模式）
    // 定期处理缓存
//    NSURLCache *cache = [NSURLCache sharedURLCache];
//    NSCachedURLResponse *response = [cache cachedResponseForRequest:request];
//    if (response) {
//        Debug_Log(@"这个请求已经存在缓存");
//    } else {
//        Debug_Log(@"这个请求没有缓存");
//    }

    // 平台类型
    // [request setValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    // [request setValue:@"iOS" forHTTPHeaderField:@"OS"];
    // 四种常见的 POST 提交数据方式
    // @"application/json", @"text/json", @"text/javascript",@"text/html",@"text/css",@"text/plain"
    // HTTP默认请求(浏览器原生支持)
    // [request setValue:@"application/x-www-form-urlencoded;charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    // HTTP提交文件(浏览器原生支持)
    // [request setValue:@"multipart/form-data" forHTTPHeaderField:@"Content-Type"];
    // JSON数据类型提交(PHP需要处理)
    // [request setValue:@"application/json;charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    // XML
    // [request setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
    // [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    __weak typeof(self) weakSelf = self;
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration
                                                          delegate:nil
                                                     delegateQueue:[NSOperationQueue mainQueue]];
    
    NSURLSessionDataTask *sessionTask = [session dataTaskWithRequest:request
    completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
    {
        // 输出返回的状态码，请求成功的话为200
#ifdef App_Log
        [weakSelf showResponseCode:response];
#endif
        // 回到主线程(此处主线程最好使用同步执行)
        dispatch_async(dispatch_get_main_queue(), ^{
            if (data) {
#ifdef App_Log
                NSLog(@"服务器响应报文Head--->:%@",response);
                NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSLog(@"服务器响应报文Body--->:%@",dataStr);
#endif
                // NSJSONReadingMutableContainers：返回可变容器，NSMutableDictionary或NSMutableArray。
                // NSJSONReadingMutableLeaves：返回的JSON对象中字符串的值为NSMutableString
                // NSJSONReadingAllowFragments：允许JSON字符串最外层既不是NSArray也不是NSDictionary，但必须是有效的JSON Fragment
                NSDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:data
                                                                            options:NSJSONReadingMutableContainers
                                                                              error:nil];
                success(responseDic, 1.0);
//                NSString *ret = [responseDic objectForKey:@"ret"];
//                if ([ret isEqualToString:@"SUCCESS"]) {
//                    success(responseDic, 1);
//                }
//                if ([ret isEqualToString:@"FAIL"]) {
//                    success(responseDic, 0);
//                }
            }
            if(error) {
                failure(error);
            }
        });
    }];
    [sessionTask resume];
}

#pragma mark - 输出HTTP响应的状态码
- (void)showResponseCode:(NSURLResponse *)response
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    NSInteger responseStatusCode = [httpResponse statusCode];
    NSSLog(@"HTTP响应的状态码--->:%d", (int)responseStatusCode);
}

@end
