//
//  ViewController.m
//  Peek
//
//  Created by pjpjpj on 2017/6/1.
//  Copyright © 2017年 #incloud. All rights reserved.
//

#import "HomeViewController.h"
#import "PJNoteCollectionView.h"
#import "PJHomeBottomView.h"
#import "PJEditImageViewController.h"
#import "PJRecognizeViewController.h"
#import "UIImage+Tag.h"
#import "Peek-Swift.h"
#import "PJCoreDateHelper.h"
#import "PJNoteViewController.h"
#import "PJUserViewController.h"
#import "PJUserLoginViewController.h"
#import <AVUser.h>

@interface HomeViewController () <PJHomeBottomViewDelegate, PJCameraViewDelegate, PJNoteCollectionViewDelegate>

@property (nonatomic, readwrite, assign) BOOL isShowCollectionView;

@property (nonatomic, readwrite, strong) PJNoteCollectionView *collectionView;
@property (nonatomic, readwrite, strong) PJHomeBottomView *bottomView;
@property (nonatomic, readwrite, strong) PJCameraView *cameraView;
@property (nonatomic, readwrite, strong) PJSegmentView *segmentView;

@property (nonatomic, readwrite, strong) UIRefreshControl *collectionViewRefreshControl;
@property (nonatomic, readwrite, strong) UIView *cameraTopView;
@property (nonatomic, readwrite, strong) UIView *cameraCaverView;
@property (nonatomic, readwrite, strong) UIButton *loginBtn;

@property (nonatomic, readwrite, assign) NSInteger segmentIndex;
@property (nonatomic, readwrite, assign) BOOL isRecaptrue;
@property (nonatomic, readwrite, assign) NSInteger recaptrueIndex;
// 拍摄的照片
@property (nonatomic, readwrite, strong) NSMutableArray *imageArray;
// 右上角照片imageView集合
@property (nonatomic, readwrite, strong) NSMutableArray *imageViewArray;

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initView];
}

// MARK: layz load

- (UIView *)cameraTopView {
    if (!_cameraTopView) {
        _cameraTopView = ({
            UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.bottomView.width, self.bottomView.height / 3 * 2)];
            [self.view addSubview:topView];
            topView.alpha = 0;
            topView.hidden = YES;
            
            UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(cameraTopViewPan:)];
            [topView addGestureRecognizer:pan];
            
            CAGradientLayer *gradientLayer = [CAGradientLayer layer];
            gradientLayer.frame = topView.bounds;
            gradientLayer.colors =@[(__bridge id)[UIColor whiteColor].CGColor, (__bridge id)[UIColor colorWithWhite:2.0 alpha:0.01].CGColor];
            gradientLayer.locations = @[@0.1];
            gradientLayer.endPoint = CGPointMake(0.0, 1.0);
            gradientLayer.startPoint = CGPointMake(0.0, 0.0);
            [topView.layer addSublayer:gradientLayer];
            
            _segmentView = ({
                PJSegmentView *segmentView = [[PJSegmentView alloc] initWithFrame:CGRectMake(0, 0, topView.width / 2, topView.height / 2)];
                segmentView.centerX = topView.centerX;
                segmentView.centerY = topView.centerY;
                [topView addSubview:segmentView];
                segmentView.menuArray = @[@"红色", @"蓝色", @"整版扫描"];
                segmentView;
            });
            
            topView;
        });
    }
    return _cameraTopView;
}

- (UIView *)cameraCaverView {
    if (!_cameraCaverView) {
        _cameraCaverView = ({
            UIView *caverView = [[UIView alloc] initWithFrame:self.view.frame];
            [self.view addSubview:caverView];
            caverView.backgroundColor = [UIColor whiteColor];
            caverView.alpha = 0;
            caverView.hidden = YES;
            caverView;
        });
    }
    return _cameraCaverView;
}

// MARK: life cycle

- (void)initView {
    self.navBar.hidden = YES;
    self.isRecaptrue = NO;
    self.view.backgroundColor = [UIColor whiteColor];
    self.segmentIndex = 0;
    self.recaptrueIndex = 0;
    
    self.isShowCollectionView = YES;
    self.imageArray = [NSMutableArray new];
    self.imageViewArray = [NSMutableArray new];
    
    self.collectionViewRefreshControl = [UIRefreshControl new];
    [self.collectionViewRefreshControl addTarget:self
                                          action:@selector(refreshAction)
                                forControlEvents:UIControlEventValueChanged];
    
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"isFirstComming"]) {
        [[NSUserDefaults standardUserDefaults] setObject:@(true) forKey:@"isFirstComming"];
        [[PJCoreDateHelper shareInstance] initNoteDate];
    }
    
    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.itemSize = CGSizeMake(SCREEN_WIDTH * 0.4, SCREEN_WIDTH * 0.4 * 1.3);
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.headerReferenceSize=CGSizeMake(self.view.width, 100);
    layout.minimumLineSpacing = 25;
    layout.minimumInteritemSpacing = 25;
    layout.sectionInset = UIEdgeInsetsMake(25, 25, 25, 25);
    self.collectionView = [[PJNoteCollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, self.view.height) collectionViewLayout:layout];
    self.collectionView.isUserHeader = YES;
    self.collectionView.viewDelegate = self;
    [self.collectionView addSubview:self.collectionViewRefreshControl];
    [self.view addSubview:self.collectionView];
    self.collectionView.dataArray = [[PJCoreDateHelper shareInstance] getNoteData];
    [self.collectionView reloadData];

    self.cameraView = [[PJCameraView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    [self.view addSubview:self.cameraView];
    self.cameraView.hidden = YES;
    self.cameraView.alpha = 0;
    self.cameraView.viewDelegate = self;
    
    self.bottomView = [[PJHomeBottomView alloc] initWithFrame:CGRectMake(0, self.view.height - 100, self.view.width, 100)];
    self.bottomView.viewDelegate = self;
    [self.view addSubview:self.bottomView];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(cameraViewPan:)];
    [self.bottomView addGestureRecognizer:pan];
    
    self.loginBtn = [[UIButton alloc] initWithFrame:CGRectMake(20, (self.bottomView.height - self.bottomView.height / 2) / 2 + 10, self.bottomView.width - 40, self.bottomView.height * 0.5)];
    [self.bottomView addSubview:self.loginBtn];
    self.loginBtn.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    self.loginBtn.backgroundColor = [UIColor whiteColor];
    self.loginBtn.layer.borderColor = RGB(150, 150, 150).CGColor;
    self.loginBtn.layer.borderWidth = 1;
    [self.loginBtn setTitle:@"👉 登录开启全新学习方式 👈" forState:UIControlStateNormal];
    [self.loginBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.loginBtn addTarget:self action:@selector(loginBtnClick) forControlEvents:UIControlEventTouchUpInside];
    
    if (AVUser.currentUser) {
        self.loginBtn.hidden = YES;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(PJRecognizeViewControllerRecaptrue:)
                                                 name:PJRecognizeViewControllerRecaptrueNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userloginSuccess) name:PJUserLoginViewControllerUserLoginSuccess object:nil];
}

// MARK: UI response
- (void)homeBottomViewButtonClick {
    [self.cameraView takePhoto];
}

- (void)loginBtnClick {
    PJUserLoginViewController *vc = [PJUserLoginViewController new];
    vc.imageView = [PJTool convertCreateImageWithUIView:self.view];
    [self presentViewController:vc animated:YES completion:nil];
}

-(void)refreshAction {
    NSLog(@"下拉刷新");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.collectionViewRefreshControl endRefreshing];
    });
}

- (void)cameraTopViewPan:(UIPanGestureRecognizer *)ges {
    
    [self.view bringSubviewToFront:self.cameraCaverView];
    [self.view bringSubviewToFront:self.collectionView];
    
    CGPoint p = [ges translationInView:self.bottomView];
    CGRect frame = self.collectionView.frame;
    frame.origin.y = p.y - self.collectionView.height;
    self.collectionView.frame = frame;

    self.cameraCaverView.hidden = NO;
    self.cameraCaverView.alpha = p.y * 0.0015625;
    
    if (ges.state == UIGestureRecognizerStateEnded) {
        if (frame.origin.y > -self.view.height / 2) {
            frame.origin.y = 0;
            [UIView animateWithDuration:0.25 animations:^{
                self.collectionView.frame = frame;
            } completion:^(BOOL finished) {
                self.cameraView.hidden = YES;
                self.cameraTopView.hidden = YES;
                self.cameraCaverView.hidden = YES;
                self.isShowCollectionView = YES;

                [self.view bringSubviewToFront:self.bottomView];
                self.bottomView.isShowHomeButton = NO;
            }];
        } else {
            [UIView animateWithDuration:0.25 animations:^{
                self.collectionView.y = -self.collectionView.height;
            } completion:^(BOOL finished) {
                self.cameraCaverView.hidden = YES;
                self.cameraCaverView.alpha = 0;
            }];
        }
    }
    
}

- (void)cameraViewPan:(UIPanGestureRecognizer *)ges {
    if (!self.isShowCollectionView) {
        return;
    }
    
    CGPoint p = [ges translationInView:self.bottomView];
    CGRect frame = self.collectionView.frame;
    frame.origin.y = p.y;
    
    self.cameraView.hidden = NO;
    self.cameraView.alpha = -p.y * 0.0015625;
    self.collectionView.frame = frame;
    
    if (ges.state == UIGestureRecognizerStateEnded) {
        if (frame.origin.y < -self.view.height / 2) {
            frame.origin.y = - self.collectionView.height;
            [UIView animateWithDuration:0.25 animations:^{
                self.collectionView.frame = frame;
            } completion:^(BOOL finished) {
                if (finished) {
                    self.isShowCollectionView = NO;
                    [UIView animateWithDuration:0.25 animations:^{
                        self.cameraView.alpha = 1;
                    }];
                    [UIView animateWithDuration:0.25 animations:^{
                        self.cameraView.alpha = 1;
                        self.cameraTopView.hidden = NO;
                        self.cameraTopView.alpha = 1;
                    } completion:^(BOOL finished) {
                        if (finished) {
                            [self.view bringSubviewToFront:self.cameraTopView];
                            [self.view bringSubviewToFront:self.bottomView];
                            self.bottomView.isShowHomeButton = YES;
                        }
                    }];
                }
            }];
        } else {
            frame.origin.y = 0;
            [UIView animateWithDuration:0.25 animations:^{
                self.collectionView.frame = frame;
            } completion:^(BOOL finished) {
                if (finished) {
                    self.isShowCollectionView = YES;
                    self.cameraView.hidden = YES;
                    self.cameraView.alpha = 0;
                }
            }];
        }
    }
}

// MARK: delegate

- (void)cameraView:(UIImage *)takePhotoImage {
    takePhotoImage.type = [NSString stringWithFormat:@"%d", (int)self.segmentIndex];
    if (self.isRecaptrue) {
        self.imageArray[self.recaptrueIndex] = takePhotoImage;
        [self photoImageTapClick];
        self.isRecaptrue = NO;
        return;
    }
    
    [self.imageArray addObject:takePhotoImage];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.cameraView.frame];
    imageView.transform = CGAffineTransformMakeScale(0.8, 0.8);
    imageView.image = takePhotoImage;
    imageView.layer.cornerRadius = 50;
    imageView.layer.borderWidth = 10;
    imageView.layer.borderColor = [UIColor whiteColor].CGColor;
    imageView.layer.masksToBounds = YES;
    [self.view addSubview:imageView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(photoImageTapClick)];
    [imageView addGestureRecognizer:tap];
    imageView.userInteractionEnabled = YES;
    
    NSInteger imageCount = self.imageArray.count;
    if (imageCount > 3) {
        imageCount = 3;
    }
    [UIView animateWithDuration:0.4 animations:^{
        imageView.transform = CGAffineTransformMakeScale(0.08, 0.08);
        imageView.right = self.cameraView.width - 5;
        imageView.y = self.cameraTopView.bottom;
        
        imageView.y += imageCount * 2;
        imageView.x -= imageCount * 2;
    } completion:^(BOOL finished) {
        if (finished) {
            [self.imageViewArray addObject:imageView];
        }
    }];
}

- (void)photoImageTapClick {
    PJRecognizeViewController *vc = [PJRecognizeViewController new];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    vc.imageArray = [self.imageArray mutableCopy];
    // 初始值为0，也相当于重头开始
    vc.photoIndex = self.recaptrueIndex;

    [self presentViewController:nav animated:YES completion:^{
        for (UIImageView *imageView in self.imageViewArray) {
            [imageView removeFromSuperview];
        }
        [self.imageViewArray removeAllObjects];
        [self.imageArray removeAllObjects];
        self.recaptrueIndex = 0;
    }];
}

- (void)PJNoteCollectionViewdidSelectedIndex:(NSInteger)index noteTitle:(NSString *)noteTitle noteImage:(UIImage *)noteImage {
    NSArray *dataArray = [[PJCoreDateHelper shareInstance] getCardData:index];
    if (dataArray.count == 0) {
        [PJTapic error];
        return;
    }
    PJNoteViewController *vc = [PJNoteViewController new];
    vc.dataArray = dataArray;
    vc.noteTitle = noteTitle;
    vc.noteImage = noteImage;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)swipeGestureWithDirection:(UISwipeGestureRecognizerDirection)direction {
    if (direction == UISwipeGestureRecognizerDirectionLeft) {
        if (self.segmentIndex != 0) {
            self.segmentIndex --;
        }
    } else {
        if (self.segmentIndex < self.segmentView.menuArray.count - 1) {
            self.segmentIndex ++;
        }
    }
    self.segmentView.segmentIndex = [NSNumber numberWithInteger:self.segmentIndex];
    [self.segmentView menuMoveByIndexWithIndex:self.segmentIndex];
}

- (void)PJRecognizeViewControllerRecaptrue:(NSNotification *)notify {
    self.recaptrueIndex = [notify.userInfo[@"index"] intValue];
    self.imageArray = notify.userInfo[@"imageArray"];
    self.isRecaptrue = YES;
}

- (void)PJNoteCollectionViewHeaderViewAvatarBtnClick {
    PJUserViewController *vc = [PJUserViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)userloginSuccess {
    self.loginBtn.hidden = YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:PJRecognizeViewControllerRecaptrueNotification];
}

@end
