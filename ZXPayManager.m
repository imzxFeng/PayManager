//
//  ZXPayManager.m
//  PatientAPP
//
//  Created by FZX on 2018/5/3.
//  Copyright © 2018年 yikang. All rights reserved.
//

#import "ZXPayManager.h"
static ZXPayManager *staticPayManager;
@implementation ZXPayManager
{
    NSString *sureUrl;
    NSString *order_id;
    NSString *user_id;
    NSInteger _source;
    dispatch_source_t _timer;
}

+ (instancetype)sharedInstance
{
    if (!staticPayManager){
        static dispatch_once_t token ;
        dispatch_once(&token, ^{
            staticPayManager = [[ZXPayManager alloc] init];
        });
    }
    return staticPayManager;
}

- (instancetype)init{
    self = [super init];
    if (self) {
       
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getOrderPayResult:) name:PayResultNotification object:nil];
    }
    return self;
}



#pragma mark -  支付操作 生成订单
- (void)requestCreatOrder:(NSString *)creat_url
                 sure_url:(NSString *)sure_url
                   pay_id:(NSInteger)pay_id
                parameter:(NSDictionary *)parameter
           viewController:(UIViewController *)vc
                   source:(NSInteger)source  //0 患者支付   1医生支付
               orderBlock:(void(^)(NSString *is_pay, NSDictionary *dic))orderBlock//0 生成订单失败  3 不需要支付  4代付
              resultBlock:(void(^)(NSString *result, NSDictionary *dic))resultBlock//0支付失败  1支付成功  2支付取消
{
    _payResult = resultBlock;
    _vc = vc;
    sureUrl = sure_url;
    user_id = parameter[@"user_id"];
    _source = source;
    if (source == 0) {
        [self patientCreatOrderWithCreat_url:creat_url
                                   parameter:parameter
                                      pay_id:pay_id
                                  orderBlock:orderBlock
                                 resultBlock:resultBlock];
    }
    else if (source == 1){
        [self doctorCreatOrderWithCreat_url:creat_url
          parameter:parameter
             pay_id:pay_id
         orderBlock:orderBlock
        resultBlock:resultBlock];
    }
}

#pragma mark -  医生支付生成订单
- (void)doctorCreatOrderWithCreat_url:(NSString *)creat_url
                             parameter:(NSDictionary *)parameter
                                pay_id:(NSInteger)pay_id
                            orderBlock:(void(^)(NSString *is_pay, NSDictionary *dic))orderBlock//0 生成订单失败  3 不需要支付  4代付
                           resultBlock:(void(^)(NSString *result, NSDictionary *dic))resultBlock//0支付失败  1支付成功  2支付取消
{
    [[ARFZXHttpManager sharedInstance] requestWithUrl:creat_url
                                          Enparameter:parameter
                                            Parameter:@{}
                                        completeBlock:^(NSError *error, id result) {
                                            NSInteger status = [EncodeFromDic(result, @"status") integerValue];
                                            if (status == 1) {///成功  调起支付
                                                
                                                order_id = EncodeFromDic(result, @"order_sn");
                                                
                                                if (pay_id == 1) {///微信支付
                                                    
                                                    NSDictionary *wx_api = result[@"order_obj"];
                                                    NSString *appid = EncodeFromDic(wx_api, @"appid");
                                                    NSString *noncestr = EncodeFromDic(wx_api, @"noncestr");
                                                    NSString *package = EncodeFromDic(wx_api, @"package");
                                                    NSString *partnerid = EncodeFromDic(wx_api, @"partnerid");
                                                    NSString *prepayid = EncodeFromDic(wx_api, @"prepayid");
                                                    NSString *sign = EncodeFromDic(wx_api, @"sign");
                                                    NSString *timestamp = EncodeFromDic(wx_api, @"timestamp");
                                                    
                                                    
                                                    [self weChatPayWithAppid:appid
                                                                   partnerid:partnerid
                                                                    prepayid:prepayid
                                                                     package:package
                                                                    noncestr:noncestr
                                                                   timestamp:timestamp
                                                                        sign:sign];
                                                }
                                                else if (pay_id == 2){///支付宝支付
                                                    
                                                    NSString *ali_api = EncodeFromDic(result, @"order_str");
                                                    [self aliPayWithApi:ali_api];
                                                }
                                                else if (pay_id == 3){
                                                    orderBlock(@"4",result);//代付
                                                }
                                                else if (pay_id == 0){//0元
                                                    orderBlock(@"3",result);
                                                }
                                            }
                                            else if (status == 3){//状态是3,0元支付或者会话未结束
                                                orderBlock(@"3",result);
                                            }
                                            else{
                                                [_vc displayToast:result[@"message"]];
                                                orderBlock(@"0",result);//生成订单失败
                                            }
                                        }];
}


#pragma mark -  代付生成订单
- (void)patientCreatOrderWithCreat_url:(NSString *)creat_url
                             parameter:(NSDictionary *)parameter
                                pay_id:(NSInteger)pay_id
                            orderBlock:(void(^)(NSString *is_pay, NSDictionary *dic))orderBlock//0 生成订单失败  3 不需要支付  4代付
                           resultBlock:(void(^)(NSString *result, NSDictionary *dic))resultBlock//0支付失败  1支付成功  2支付取消
{
   
    [[ARFZXHttpManager sharedInstance] requestPatientWithUrl:creat_url
      Enparameter:parameter
        Parameter:@{}
    completeBlock:^(NSError *error, id result) {
        NSInteger status = [EncodeFromDic(result, @"status") integerValue];
        if (status == 1) {///成功  调起支付
            
            order_id = EncodeFromDic(result, @"order_sn");
            
            if (pay_id == 1) {///微信支付
                
                NSDictionary *wx_api = result[@"order_obj"];
                NSString *appid = EncodeFromDic(wx_api, @"appid");
                NSString *noncestr = EncodeFromDic(wx_api, @"noncestr");
                NSString *package = EncodeFromDic(wx_api, @"package");
                NSString *partnerid = EncodeFromDic(wx_api, @"partnerid");
                NSString *prepayid = EncodeFromDic(wx_api, @"prepayid");
                NSString *sign = EncodeFromDic(wx_api, @"sign");
                NSString *timestamp = EncodeFromDic(wx_api, @"timestamp");
                
                
                [self weChatPayWithAppid:appid
                               partnerid:partnerid
                                prepayid:prepayid
                                 package:package
                                noncestr:noncestr
                               timestamp:timestamp
                                    sign:sign];
            }
            else if (pay_id == 2){///支付宝支付
                
                NSString *ali_api = EncodeFromDic(result, @"order_str");
                [self aliPayWithApi:ali_api];
            }
            else if (pay_id == 3){
                orderBlock(@"4",result);//代付
            }
        }
        else if (status == 3){//状态是3,0元支付或者会话未结束
            orderBlock(@"3",result);
        }
        else{
            [_vc displayToast:result[@"message"]];
            orderBlock(@"0",result);//生成订单失败
        }
    }];
}

#pragma mark - 支付宝支付
- (void)aliPayWithApi:(NSString *)api{
    [[AlipaySDK defaultService]payOrder:api fromScheme:APP_scheme callback:^(NSDictionary *resultDic) {
        ///网页版在此回调
        NSString *result = @"";
        if ([resultDic[@"ResultStatus"] isEqualToString:@"9000"]) {///支付成功
            NSLog(@"支付成功");
            result = @"1";
        }else{///支付失败
            NSLog(@"支付失败");
            result = @"0";
        }
        
        //支付返回结果，实际支付结果需要去自己的服务器端查询
        NSNotification *notification = [NSNotification notificationWithName:PayResultNotification object:result];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    }];
}

#pragma mark 微信支付方法
- (void)weChatPayWithAppid:(NSString *)appid
                 partnerid:(NSString *)partnerid
                  prepayid:(NSString *)prepayid
                   package:(NSString *)package
                  noncestr:(NSString *)noncestr
                 timestamp:(NSString *)timestamp
                      sign:(NSString *)sign
{
    
    //需要创建这个支付对象
    PayReq *req   = [[PayReq alloc] init];
    //由用户微信号和AppID组成的唯一标识，用于校验微信用户
    req.openID = appid;
    // 商家id，在注册的时候给的
    req.partnerId = partnerid;
    // 预支付订单这个是后台跟微信服务器交互后，微信服务器传给你们服务器的，你们服务器再传给你
    req.prepayId  = prepayid;
    // 根据财付通文档填写的数据和签名
    req.package  = package;
    // 随机编码，为了防止重复的，在后台生成
    req.nonceStr  = noncestr;
    // 这个是时间戳，也是在后台生成的，为了验证支付的
    NSString * stamp = timestamp;
    req.timeStamp = stamp.intValue;
    // 这个签名也是后台做的
    req.sign = sign;
    
    
    // 判断手机有没有微信
    if ([WXApi isWXAppInstalled]) {
        NSLog(@"已经安装了微信...");
        //发送请求到微信，等待微信返回onResp
        [WXApi sendReq:req];
    }else{
        NSLog(@"没有安装微信...");
        [_vc displayToast:@"没有安装微信"];
    }
    
}

#pragma mark - 收到支付成功的消息后作相应的处理    1:支付成功  0：支付失败  2：退出支付
- (void)getOrderPayResult:(NSNotification *)notification
{
    if ([notification.object isEqualToString:@"1"]) {//支付成功

        [self begincountdown];
    }
    else if ([notification.object isEqualToString:@"0"]){//支付失败
        BLOCK_EXEC(_payResult,@"0",nil);
        [_vc displayToast:@"支付失败"];
        
    }
    else {//退出支付
        NSLog(@"支付取消");
        BLOCK_EXEC(_payResult,@"2",nil);
        [_vc displayToast:@"支付取消"];
    }
}

#pragma mark -- 发送验证码倒计时
- (void)begincountdown{
    NSTimeInterval period = 0.5; //设置时间间隔
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(_timer, dispatch_walltime(NULL, 0), period * NSEC_PER_SEC, 0); //每秒执行
    dispatch_source_set_event_handler(_timer, ^{
        //在这里执行事件
        static NSInteger t = 1;
        if (_source == 0) {
            [self verifyPayResultWitht:t];
        }
        else if (_source == 1){
            [self doctorVerifyPayResultWitht:t];
        }
        if (t == 5) {
            // 关闭定时器
            dispatch_source_cancel(_timer);
        }
        t++;
    });
    //开启定时器
    dispatch_resume(_timer);
}

- (void)verifyPayResultWitht:(NSInteger)t{
    [[ARFZXHttpManager sharedInstance] requestPatientWithUrl:sureUrl
                                                 Enparameter:@{@"order_sn":order_id,
                                                               @"user_id":user_id
                                                               }
                                                   Parameter:@{}
                                               completeBlock:^(NSError *error, id result) {
                                                   
                                                   NSInteger status = [EncodeFromDic(result, @"status") integerValue];
                                                   
                                                   if (status == 1) {//成功
                                                       BLOCK_EXEC(_payResult,@"1",result);
                                                       // 关闭定时器
                                                       dispatch_source_cancel(_timer);
                                                   }
                                                   else{
                                                       if (t == 5) {
                                                           [_vc displayToast:@"支付失败"];
                                                           
                                                           BLOCK_EXEC(_payResult,@"0",nil);
                                                           // 关闭定时器
                                                           dispatch_source_cancel(_timer);
                                                       }
                                                   }
                                               }];
    
}



- (void)doctorVerifyPayResultWitht:(NSInteger)t{
    
    [[ARFZXHttpManager sharedInstance] requestWithUrl:sureUrl
                                          Enparameter:@{@"order_sn":order_id,
                                          }
                                            Parameter:@{}
                                        completeBlock:^(NSError *error, id result) {
                                            
                                            NSInteger status = [EncodeFromDic(result, @"status") integerValue];
                                            
                                            if (status == 1) {//成功
                                                NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:result];
                                                [dic setObject:order_id forKey:@"order_sn"];
                                                BLOCK_EXEC(_payResult,@"1",dic);
                                                // 关闭定时器
                                                dispatch_source_cancel(_timer);
                                            }
                                            else{
                                                if (t == 5) {
                                                    [_vc displayToast:@"支付失败"];
                                                    
                                                    BLOCK_EXEC(_payResult,@"0",nil);
                                                    // 关闭定时器
                                                    dispatch_source_cancel(_timer);
                                                }
                                            }
                                        }];
}



@end
