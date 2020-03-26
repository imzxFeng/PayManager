//
//  ZXPayManageController.m
//  PatientAPP
//
//  Created by ZX on 2018/4/11.
//  Copyright © 2018年 yikang. All rights reserved.
//
#define optionHeight 57
#import "ZXPayManageController.h"
#import "ZXPayManager.h"
@interface ZXPayManageController ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UITapGestureRecognizer *recognizerTap;
@property (nonatomic, strong) NSArray *payArr;
@property (nonatomic, strong) NSString *creat_url;
@property (nonatomic, strong) NSString *sure_url;
@property (nonatomic, strong) NSDictionary *parameter;
@property (nonatomic, strong) UIViewController *vc;
@property (nonatomic, assign) NSInteger source;
@end

@implementation ZXPayManageController

+ (instancetype)initWithPayarray:(NSArray *)payArray
                      creat_url:(NSString *)creat_url
                       sure_url:(NSString *)sure_url
                      parameter:(NSDictionary *)parameter
                  viewcontroller:(UIViewController *)vc
                          source:(NSInteger)source  //0 患者支付   1医生支付
                     resultBlock:(void(^)(NSString *result, NSDictionary *dic))block
{
    ZXPayManageController *sheet = [[ZXPayManageController alloc]initWithPayArr:payArray];
    sheet.payCallBack = block;
    sheet.creat_url = creat_url;
    sheet.sure_url = sure_url;
    sheet.parameter = parameter;
    sheet.vc = vc;
    sheet.source = source;
    return sheet;
}

- (instancetype)initWithPayArr:(NSArray *)payArr;
{
    self = [super init];
    if (self) {
        
        self.payArr = payArr;
        
        _recognizerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapBehind:)];
        [_recognizerTap setNumberOfTapsRequired:1];
        _recognizerTap.cancelsTouchesInView = NO;
        [self.view addGestureRecognizer:_recognizerTap];
        
        _containerView = [UIView new];
        [self.view addSubview:_containerView];
        _containerView.backgroundColor = [UIColor whiteColor];
        
        CGFloat height = optionHeight * _payArr.count;
        [_containerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.view);
            make.width.equalTo(self.view).offset(-26);
            make.bottom.equalTo(self.view).offset(-14);
            make.height.mas_offset(height);
        }];
        
        _containerView.layer.masksToBounds = YES;
        _containerView.layer.cornerRadius = 10.0;
        
        [self setPayManner];
    }
    return self;
}

- (void)setPayManner{
   
    for (int i = 0; i < _payArr.count; i++) {
        PAPayModel *model = _payArr[i];
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_containerView addSubview:btn];
        btn.tag = i;
        [btn addTarget:self action:@selector(payBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        CGFloat btnY = optionHeight * i;
        [btn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.width.equalTo(_containerView);
            make.top.equalTo(_containerView).offset(btnY);
            make.height.mas_offset(optionHeight);
        }];
        
        UIImageView *img = [[UIImageView alloc]init];
        [btn addSubview:img];
        [img sd_setImageWithURL:[NSURL URLWithString:model.img]];
        [img mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(btn);
            make.right.equalTo(btn.mas_centerX).offset(-20);
            make.width.height.mas_offset(25);
        }];
        
        UILabel *name = [[UILabel alloc]init];
        name.font = AR_FONT18;
        name.textColor = [UIColor blackColor];
        name.text = model.name;
        [btn addSubview:name];
        [name mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(btn);
            make.left.equalTo(img.mas_right).offset(5);
        }];
        UIView *line = [UIView new];
        [btn addSubview:line];
        line.backgroundColor = AR_RGBCOLOR(244, 244, 244);
        [line mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.centerX.width.equalTo(btn);
            make.height.mas_offset(0.5);
        }];
    }
}

- (void)payBtnClick:(UIButton *)btn{

    PAPayModel *model = _payArr[btn.tag];
    int ID = [model.ID intValue];
    NSMutableDictionary *mutDic = _parameter.mutableCopy;
    [mutDic setObject:@(ID) forKey:@"pay_code"];
    [[ZXPayManager sharedInstance] requestCreatOrder:_creat_url
                                            sure_url:_sure_url
                                              pay_id:ID
                                           parameter:mutDic
                                      viewController:_vc
                                              source:_source
                                          orderBlock:^(NSString *is_pay, NSDictionary *dic) {
                                          
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  [self dismissViewControllerAnimated:YES completion:^{
                                                      if (_payCallBack) {
                                                          _payCallBack(is_pay,dic);
                                                      }
                                                  }];
                                              });
                                      } resultBlock:^(NSString *result, NSDictionary *dic) {
                                        
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                              [self dismissViewControllerAnimated:YES completion:^{
                                                  if (_payCallBack) {
                                                      _payCallBack(result,dic);
                                                  }
                                              }];
                                          });
                                        
                                      }];
    
}






// 点击其他区域关闭弹窗
- (void)handleTapBehind:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded){
        CGPoint location = [sender locationInView:nil];
        if (![_containerView pointInside:[_containerView convertPoint:location fromView:_containerView.superview] withEvent:nil]){
            //                if ([_containerView.textView resignFirstResponder]) {// 如果有键盘先收起键盘
            //                    [_containerView.textView resignFirstResponder];
            //                    return;
            //                }
            [_containerView.window removeGestureRecognizer:sender];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}


- (ZXModallyAnimationController *)animationController {
    ZXModallyAnimationController *animation = [[ZXModallyAnimationController alloc]init];
    animation.animationStyle = WSModallyAnimationStyleActionSheet;
    animation.position = WSAnimationStartBottom;
    return animation;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
