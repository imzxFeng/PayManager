//
//  ZXPayManager.h
//  PatientAPP
//
//  Created by FZX on 2018/5/3.
//  Copyright © 2018年 yikang. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void(^PayResultBlock)(NSString *result,NSDictionary *dic);
@interface ZXPayManager : NSObject

@property (nonatomic, copy)PayResultBlock payResult;
@property (nonatomic, weak)UIViewController *vc;

+ (instancetype)sharedInstance;

- (void)requestCreatOrder:(NSString *)creat_url
                 sure_url:(NSString *)sure_url
                   pay_id:(NSInteger)pay_id
                parameter:(NSDictionary *)parameter
           viewController:(UIViewController *)vc
                   source:(NSInteger)source  //0 患者支付   1医生支付
               orderBlock:(void(^)(NSString *is_pay, NSDictionary *dic))orderBlock//0 生成订单失败  3 不需要支付  4代付
              resultBlock:(void(^)(NSString *result, NSDictionary *dic))resultBlock;//0支付失败  1支付成功  2支付取消
@end
