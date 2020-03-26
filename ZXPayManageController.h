//
//  ZXPayManageController.h
//  PatientAPP
//
//  Created by ZX on 2018/4/11.
//  Copyright © 2018年 yikang. All rights reserved.
//

#import "ZXModallyViewController.h"
#import "PAPayModel.h"
typedef void(^PayCallBackBlock)(NSString *, NSDictionary *);
@interface ZXPayManageController : ZXModallyViewController

@property (nonatomic, copy) PayCallBackBlock payCallBack;

+ (instancetype)initWithPayarray:(NSArray *)payArray
                       creat_url:(NSString *)creat_url
                        sure_url:(NSString *)sure_url
                       parameter:(NSDictionary *)parameter
                  viewcontroller:(UIViewController *)vc
                          source:(NSInteger)source  //0 患者支付   1医生支付
                     resultBlock:(void(^)(NSString *result, NSDictionary *dic))block;
@end
