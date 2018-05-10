//
//  PayPlugin.m
//  TestChinaPay
//
//  Created by Dafiger on 2018/4/11.
//  Copyright © 2018年 wpf. All rights reserved.
//

#import "PayPlugin.h"

@implementation AppleNetPlugin

#pragma mark - 获取单例
+ (AppleNetPlugin *)instance
{
    static AppleNetPlugin *sharedManagerInstance = nil;
    static dispatch_once_t predicate = 0;
    dispatch_once( &predicate, ^{
        sharedManagerInstance = [[self alloc] init];
    });
    return sharedManagerInstance;
}

#pragma mark - get请求
- (void)req_GetWithUrlStr:(NSString *)urlStr
                  success:(void(^)(id response, BOOL verify))success
                  failure:(void(^)(id error))failure
{
    NSURL *url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    [request setHTTPShouldHandleCookies:FALSE];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration
                                                          delegate:nil
                                                     delegateQueue:[NSOperationQueue mainQueue]];
    
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *sessionTask = [session dataTaskWithRequest:request
                                                   completionHandler:
    ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
    {
        // 响应状态码
        [weakSelf showResponseCode:response];
        
        if (error) {
            PayLog(@"GET请求接口失败:%@，失败原因--->:%@",urlStr, error);
        }
        Pay_MAIN(^{
            NSString *responseStr = [[NSString alloc] initWithData:data
                                                          encoding:NSUTF8StringEncoding];
            PayLog(@"GET请求接口成功:%@，数据--->:%@",urlStr, responseStr);
            
            if (Pay_StringIsEmpty(responseStr)) {
                PayLog(@"GET返回数据为空");
                success(nil, 0);
            }else{
                NSDictionary *responseDic = [PayTools jsonStrToObject:responseStr];
                if (Pay_DictIsEmpty(responseDic)) {
                    PayLog(@"GET返回数据格式错误");
                    success(nil, 0);
                }else{
                    success(responseDic, 1);
                }
            }
        });
    }];
    // 开始请求
    [sessionTask resume];
}

#pragma mark - post请求
- (void)req_PostWithUrlStr:(NSString *)urlStr
                  paramDic:(NSDictionary *)paramDic
                   bodyStr:(NSString *)bodyStr
                   success:(void(^)(id response, BOOL verify))success
                   failure:(void(^)(id error))failure
              showProgress:(BOOL)isShowProgress
{
    NSMutableString *req_str = [NSMutableString string];
    if (bodyStr.length) {
        [req_str appendString:bodyStr];
    }else{
        NSArray *keyAry = [paramDic allKeys];
        for (int i=0; i<keyAry.count; i++) {
            NSString *keyStr = keyAry[i];
            [req_str appendString:[NSString stringWithFormat:@"%@=%@", keyStr, [paramDic objectForKey:keyStr]]];
            if (i != keyAry.count - 1) {
                [req_str appendString:@"&"];
            }
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
    // 1、HTTP默认请求(浏览器原生支持)
    // [request setValue:@"application/x-www-form-urlencoded;charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    // 2、HTTP提交文件(浏览器原生支持)
    // [request setValue:@"multipart/form-data" forHTTPHeaderField:@"Content-Type"];
    // 3、JSON数据类型提交(PHP需要处理)
    // [request setValue:@"application/json;charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    // 4、XML
    // [request setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
    // [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    __weak typeof(self) weakSelf = self;
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration
                                                          delegate:nil
                                                     delegateQueue:[NSOperationQueue mainQueue]];
    
    NSURLSessionDataTask *sessionTask = [session dataTaskWithRequest:request
                                                   completionHandler:
    ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
    {
        // 响应状态码
        [weakSelf showResponseCode:response];
        
        if (error) {
            PayLog(@"POST请求接口失败:%@，失败原因--->:%@",urlStr, error);
        }
        Pay_MAIN(^{
            NSString *responseStr = [[NSString alloc] initWithData:data
                                                          encoding:NSUTF8StringEncoding];
            PayLog(@"POST请求接口成功:%@，数据--->:%@",urlStr, responseStr);
            
            if (Pay_StringIsEmpty(responseStr)) {
                PayLog(@"POST返回数据为空");
                success(nil, 0);
            }else{
                NSDictionary *responseDic = [PayTools jsonStrToObject:responseStr];
                if (Pay_DictIsEmpty(responseDic)) {
                    PayLog(@"POST返回数据格式错误");
                    success(nil, 0);
                }else{
                    success(responseDic, 1);
                }
            }
        });
    }];
    [sessionTask resume];
}

#pragma mark - 输出HTTP响应的状态码
- (void)showResponseCode:(NSURLResponse *)response
{
    // 取出报文头的信息
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    NSInteger responseStatusCode = [httpResponse statusCode];
    PayLog(@"HTTP响应的状态码--->:%d", (int)responseStatusCode);
}

@end
