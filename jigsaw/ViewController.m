//
//  ViewController.m
//  jigsaw
//
//  Created by 李锐 on 2017/4/12.
//  Copyright © 2017年 lirui. All rights reserved.
//

#import "ViewController.h"

#define row 3
#define col 3

#define ScreenWidth  [UIScreen mainScreen].bounds.size.width
#define ScreenHeight  [UIScreen mainScreen].bounds.size.height


@interface ViewController ()
@property (nonatomic,strong) UIImageView * bgView;

@property (nonatomic,strong) UIImageView * cutView;
@property (nonatomic,assign) CGFloat moveSet;

@property (nonatomic,strong) UIImage * cutImage;
@property (nonatomic,strong) UIView * segmentView;

@property (nonatomic,assign) CGFloat smallImageWidth;

@property (nonatomic,strong) NSArray * randomArray;
//存储分割后的小图片模块
@property (nonatomic,strong) NSMutableArray * frameArray;
//存储分割后的小图片
@property (nonatomic,strong) NSMutableArray * imageArray;

@property (nonatomic,assign) NSInteger blockTag;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self createView];
    
    [self createCutView];
}


- (NSArray *)randomArray{
    if (_randomArray == nil){
        _randomArray = [NSArray array];
        _randomArray = [self createRandomArray];
    }
    return _randomArray;
}

- (NSMutableArray *)frameArray{
    if (_frameArray == nil) {
        _frameArray = [NSMutableArray array];
    }
    return _frameArray;
}

- (NSMutableArray *)imageArray{
    if (_imageArray == nil) {
        _imageArray = [NSMutableArray array];
    }
    return _imageArray;
}

- (NSArray *)createRandomArray{
    NSMutableArray * startArray = [[NSMutableArray alloc] initWithObjects:@0,@1,@2,@3,@4,@5,@6,@7,@8,nil];
    NSMutableArray * resultArray = [NSMutableArray array];
    for (int i = 0; i < 8; i++) {
        int random = arc4random() % 8;
        NSNumber * randomNum = [[NSNumber alloc]initWithInt:random];
        if ([startArray containsObject:randomNum]) {
            [resultArray addObject:randomNum];
            [startArray removeObject:randomNum];
        }
        else{
            i--;
        }
    }
    
    return resultArray;
}

- (void)createView{
    self.bgView = [[UIImageView alloc]init];
    self.bgView.image = [UIImage imageNamed:@"meizi"];
    self.bgView.contentMode = UIViewContentModeScaleAspectFit;
    
    self.bgView.translatesAutoresizingMaskIntoConstraints = false;
    [self.view addSubview:self.bgView];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[bgView]|" options:NSLayoutFormatDirectionLeftToRight metrics:nil views:@{@"bgView":self.bgView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[bgView]|" options:NSLayoutFormatDirectionLeftToRight metrics:nil views:@{@"bgView":self.bgView}]];
}

//创建裁剪浮层
- (void)createCutView{
    self.cutView = [[UIImageView alloc]init];
    self.cutView.image = [UIImage imageNamed:@"timg"];
    self.cutView.alpha = 0.5;
    self.cutView.translatesAutoresizingMaskIntoConstraints = false;
    [self.view addSubview:self.cutView];
    
    CGFloat side = [UIScreen mainScreen].bounds.size.width;
    NSNumber * sidenum = [[NSNumber alloc]initWithFloat:side];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[bgView(side)]|" options:NSLayoutFormatDirectionLeftToRight metrics:@{@"side":sidenum} views:@{@"bgView":self.cutView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[bgView(side)]" options:NSLayoutFormatDirectionLeftToRight metrics:@{@"side":sidenum} views:@{@"bgView":self.cutView}]];
}


- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch * touch = [touches anyObject];
    
    CGPoint current = [touch locationInView:self.view];
    CGPoint previous = [touch previousLocationInView:self.view];
    
    CGPoint center = self.cutView.center;
    CGPoint offset = CGPointMake(current.x - previous.x, current.y - previous.y);
    
    if (CGRectGetMinY(self.cutView.frame) >= 0 && offset.y < 0){
        self.cutView.center = CGPointMake(center.x, center.y + offset.y);
    }
    else if (CGRectGetMaxY(self.cutView.frame) <= ScreenHeight && offset.y > 0){
        self.cutView.center = CGPointMake(center.x, center.y + offset.y);
    }
    else{
        if(CGRectGetMinY(self.cutView.frame) < 0){
            self.moveSet = self.cutView.frame.origin.y;
        }
        if (CGRectGetMaxY(self.cutView.frame) > ScreenHeight) {
            CGFloat moveset = CGRectGetMaxY(self.cutView.frame) - ScreenHeight;
            self.moveSet = moveset;
        }
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    CGPoint center = self.cutView.center;
    self.cutView.center = CGPointMake(center.x, center.y - self.moveSet);
}


-(void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event{
    self.cutImage = [self cutImage];
    
    [self createSegmentImage];
    
    [self segmentImage];
    
    [self randomLayout];
    
    [self isCorrect];
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event{
    
}

// 缩放图片
- (UIImage *)scaleImage:(UIImage *)image toScale:(float)scaleSize{
    UIGraphicsBeginImageContext(CGSizeMake(image.size.width * scaleSize, image.size.height * scaleSize));
    [image drawInRect:CGRectMake(0, 0, image.size.width * scaleSize, image.size.height * scaleSize)];
    UIImage * scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

//裁剪图面
- (UIImage *)cutImage{
    UIImage * image = [UIImage imageNamed:@"meizi"];
    UIImage * scaleImage = [self scaleImage:image toScale: ScreenWidth / image.size.width];
    CGImageRef imageRef = CGImageCreateWithImageInRect(scaleImage.CGImage, self.cutView.frame);
    //将CGImage转化成UIImage
    UIImage * cutImage = [UIImage imageWithCGImage:imageRef];
    return cutImage;
}

- (void)createSegmentImage{
    
    [self.bgView removeFromSuperview];
    [self.cutView removeFromSuperview];
    
    self.segmentView = [[UIImageView alloc]init];
    self.segmentView.userInteractionEnabled = true;
    self.segmentView.contentMode = UIViewContentModeScaleAspectFit;
    
    self.segmentView.translatesAutoresizingMaskIntoConstraints = false;
    [self.view addSubview:self.segmentView];
    
    CGFloat side = ScreenWidth;
    NSNumber * sidenum = [[NSNumber alloc]initWithFloat:side];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[bgView(side)]|" options:NSLayoutFormatDirectionLeftToRight metrics:@{@"side":sidenum} views:@{@"bgView":self.segmentView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-64-[bgView]|" options:NSLayoutFormatDirectionLeftToRight metrics:@{@"side":sidenum} views:@{@"bgView":self.segmentView}]];

}

//对图片进行分割
- (void)segmentImage
{
    UIImage * image = self.cutImage;
    
    CGFloat smallImageW = image.size.width / col;
    
    
    self.smallImageWidth = smallImageW;
    
    
    CGFloat smallImageH = image.size.height / row;
    
    //边距
    CGFloat margin = 2;
    
    for (int i = 0; i < row; i++) {
        for (int j = 0; j < col; j++) {
            
            CGFloat smallImageX = margin + j * (smallImageW + margin);
            CGFloat smallImageY = margin + i * (smallImageH + margin);
            
            UIImageView * smallImageView = [[UIImageView alloc]initWithFrame:CGRectMake(smallImageX, smallImageY, smallImageW, smallImageH)];
            
            
            CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, smallImageView.frame);
            
            //将CGImage转化成UIImage
            UIImage * smallImage = [UIImage imageWithCGImage:imageRef];
            
            [self.imageArray addObject:smallImage];
            
            smallImageView.image = smallImage;
            
            smallImageView.tag = i * (col) + j + 1;
            
            [self.frameArray addObject:smallImageView];
    
        }
    }
    
}

//将拼图模块随机布局
- (void)randomLayout{
    
    NSArray * tempArray = [NSArray arrayWithArray:self.frameArray];
    
    [self.randomArray enumerateObjectsUsingBlock:^(NSNumber * num, NSUInteger idx, BOOL * _Nonnull stop) {
        int index = [num intValue];
        
        UIImageView * oldimageView = self.frameArray[index];
        UIImageView * newimageView = tempArray[idx];
        
        UIImageView * imageView = [[UIImageView alloc]initWithFrame:newimageView.frame];
        imageView.tag = index;
        imageView.userInteractionEnabled = true;
        imageView.image = oldimageView.image;
        
        [self addGestureRecgonizerOnImageView:imageView];
        
        [self.segmentView addSubview:imageView];
        
    }];
    
    UIImageView * blockView = [self.frameArray lastObject];
    blockView.tag = 998;
    blockView.userInteractionEnabled = true;
    blockView.hidden = YES;
    [self.segmentView addSubview:blockView];
    
}

- (void)addGestureRecgonizerOnImageView:(UIImageView *) imageView {
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapAction:)];
    tap.numberOfTouchesRequired = 1;
    tap.numberOfTapsRequired = 1;
    [imageView addGestureRecognizer:tap];
}

- (void)tapAction:(UITapGestureRecognizer *)tap {
    
    UIImageView * imageView = (UIImageView *)tap.view;
    
    UIImageView *blockView = (UIImageView *)[self.view viewWithTag:998];
    
    CGFloat adjacentValue = 4;
    
    BOOL isXLeftAdjacent = (fabs(CGRectGetMaxX(imageView.frame) - CGRectGetMinX(blockView.frame)) <= adjacentValue) && (imageView.frame.origin.y == blockView.frame.origin.y);
    BOOL isXRightAdjacent = (fabs(CGRectGetMinX(imageView.frame) - CGRectGetMaxX(blockView.frame)) <= adjacentValue) && (imageView.frame.origin.y == blockView.frame.origin.y);
    BOOL isYTopAdjacent = (fabs(CGRectGetMaxY(imageView.frame) - CGRectGetMinY(blockView.frame)) <= adjacentValue) && (imageView.frame.origin.x == blockView.frame.origin.x);
    BOOL isYBottomAdjacent = (fabs(CGRectGetMinY(imageView.frame) - CGRectGetMaxY(blockView.frame)) <= adjacentValue) && (imageView.frame.origin.x == blockView.frame.origin.x);
    
    if (isXLeftAdjacent || isXRightAdjacent || isYTopAdjacent || isYBottomAdjacent){
        //交换两个子视图的显示位置
        [UIView animateWithDuration:0.3 animations:^{
            CGRect rect = imageView.frame;
            imageView.frame = blockView.frame;
            blockView.frame = rect;
        } completion:^(BOOL finished) {
            [self isCorrect];
        }];
    }
}

// 判断拼图的顺序是否正确
- (void)isCorrect{
    
    __block BOOL isCorrect = YES;
    
    [self.segmentView.subviews enumerateObjectsUsingBlock:^(__kindof UIImageView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([obj isKindOfClass:[UIImageView class]]){
            
            UIImage * image = self.imageArray[idx];
            
            NSData * data1 = UIImagePNGRepresentation(obj.image);
            
//            NSLog(@"data1:%@,index:%ld",data1,idx);
            
            NSData * data2 = UIImagePNGRepresentation(image);
            
//            NSLog(@"data2:%@,index:%ld",data2,idx);
        
            
            //判断对应位置的图片是否正确
            if (![data1 isEqual:data2]) {
                isCorrect = NO;
            }
//            else{
//                NSLog(@"index:%ld",idx);
//            }
        }
         
    }];
    
//    if (isCorrect){
//        NSLog(@"拼图成功");
//    }
//    else{
//        NSLog(@"拼图失败");
//    }

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
