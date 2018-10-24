//
//  ViewController.m
//  上传图片视频
//
//  Created by juntuo on 2018/10/24.
//  Copyright © 2018 juntuo. All rights reserved.
//

#import "ViewController.h"
#import "UploadModel.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
@interface ViewController ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *imgBt;
@property (weak, nonatomic) IBOutlet UIButton *videoBt;
@property(nonatomic,strong)UIImagePickerController *imagePicker;
@property(nonatomic,strong)NSMutableArray *uploadArray;
@end

#define PHOTOCACHEPATH [NSTemporaryDirectory() stringByAppendingPathComponent:@"photoCache"]
#define VIDEOCACHEPATH [NSTemporaryDirectory() stringByAppendingPathComponent:@"videoCache"]
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.imagePicker=[[UIImagePickerController alloc]init];
    self.imagePicker.delegate = self;

}
- (IBAction)uploadImg:(id)sender {
    UIAlertController *alertController = \
    [UIAlertController alertControllerWithTitle:@""
                                        message:@"上传照片"
                                 preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *photoAction = \
    [UIAlertAction actionWithTitle:@"从相册选择"
                             style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction * _Nonnull action) {
                               NSLog(@"从相册选择");
                               self.imagePicker.sourceType  = UIImagePickerControllerSourceTypePhotoLibrary;
                               self.imagePicker.mediaTypes = @[(NSString *)kUTTypeImage];
                               self.imagePicker.allowsEditing = YES;
                               [self presentViewController:self.imagePicker
                                                  animated:YES
                                                completion:nil];
                           }];
    UIAlertAction *cameraAction = \
    [UIAlertAction actionWithTitle:@"拍照"
                             style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction * _Nonnull action) {
                               NSLog(@"拍照");
                               if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                                   self.imagePicker.sourceType    = UIImagePickerControllerSourceTypeCamera;
                                   self.imagePicker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
                                   self.imagePicker.cameraDevice   = UIImagePickerControllerCameraDeviceRear;
                                   self.imagePicker.allowsEditing   = YES;
                                   [self presentViewController:self.imagePicker
                                                      animated:YES
                                                    completion:nil];
                               }
                           }];
    UIAlertAction *cancelAction = \
    [UIAlertAction actionWithTitle:@"取消"
                             style:UIAlertActionStyleCancel
                           handler:^(UIAlertAction * _Nonnull action) {
                               NSLog(@"取消");
                           }];
    [alertController addAction:photoAction];
    [alertController addAction:cameraAction];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}
- (IBAction)uploadVideo:(id)sender {
}
//上传图片和视频
- (void)uploadImageAndMovieBaseModel:(UploadModel *)model {
    //获取文件的后缀名
    NSString *extension = [model.name componentsSeparatedByString:@"."].lastObject;
    //设置mimeType
    NSString *mimeType;

    if ([model.type isEqualToString:@"image"]) {
        mimeType = [NSString stringWithFormat:@"image/%@",extension];
    }else{
        mimeType = [NSString stringWithFormat:@"video/%@",extension];
    }

    //创建AFHTTPSessionManager


}
#pragma mark -UIImagePickerDelegate methods
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info{

     [picker dismissViewControllerAnimated:YES completion:nil];

    //获取用户选择或拍摄的是照片还是视频
    NSString *mediaType=info[UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        //获取编辑后的照片

         UIImage *tempImage = info[UIImagePickerControllerEditedImage];
        if (tempImage) {
             NSLog(@"将照片存入相册");
             UIImageWriteToSavedPhotosAlbum(tempImage, self, nil, nil);
        }
        //获取图片名称
        NSLog(@"获取图片名称");
        NSString *imageName = [self getImageNameBaseCurrentTime];
        NSLog(@"图片名称: %@", imageName);
        //将图片存入缓存
        NSLog(@"将图片写入缓存");
        [self saveImage:tempImage
            toCachePath:[PHOTOCACHEPATH stringByAppendingPathComponent:imageName]];
        //创建uploadModel
        NSLog(@"创建model");
        UploadModel *model = [[UploadModel alloc] init];
        model.path    = [PHOTOCACHEPATH stringByAppendingPathComponent:imageName];
        model.name    = imageName;
        model.type    = @"image";
        model.isUploaded = NO;
        //将模型存入待上传数组
        NSLog(@"将Model存入待上传数组");
        [self.uploadArray addObject:model];
    }else if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]){
        if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
            //如果是拍摄的视频, 则把视频保存在系统多媒体库中
             NSLog(@"video path: %@", info[UIImagePickerControllerMediaURL]);
             ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
            [library writeVideoAtPathToSavedPhotosAlbum:info[UIImagePickerControllerMediaURL] completionBlock:^(NSURL *assetURL, NSError *error) {
                if (!error) {
                    NSLog(@"视频保存成功");
                } else {
                    NSLog(@"视频保存失败");
                }
            }];
        }

         //生成视频名称
        NSString *mediaName = [self getVideoNameBaseCurrentTime];
        NSLog(@"mediaName: %@", mediaName);
        //将视频存入缓存
        NSLog(@"将视频存入缓存");
        [self saveVideoFromPath:info[UIImagePickerControllerMediaURL] toCachePath:[VIDEOCACHEPATH stringByAppendingPathComponent:mediaName]];
        //创建uploadmodel
        UploadModel *model = [[UploadModel alloc] init];
        model.path    = [VIDEOCACHEPATH stringByAppendingPathComponent:mediaName];
        model.name    = mediaName;
        model.type    = @"moive";
        model.isUploaded = NO;
        //将model存入待上传数组
        [self.uploadArray addObject:model];
    }
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 摄像头和相册相关的公共类
// 判断设备是否有摄像头
-(BOOL) isCameraAvailable{
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
}
// 前面的摄像头是否可用
- (BOOL) isFrontCameraAvailable{
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront];
}
// 后面的摄像头是否可用
- (BOOL) isRearCameraAvailable{
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
}
// 判断是否支持某种多媒体类型：拍照，视频
- (BOOL) cameraSupportsMedia:(NSString *)paramMediaType sourceType:(UIImagePickerControllerSourceType)paramSourceType{
    __block BOOL result = NO;
    if ([paramMediaType length] == 0){
        NSLog(@"Media type is empty.");
        return NO;
    }
    NSArray *availableMediaTypes =[UIImagePickerController availableMediaTypesForSourceType:paramSourceType];
    [availableMediaTypes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL*stop) {
        NSString *mediaType = (NSString *)obj;
        if ([mediaType isEqualToString:paramMediaType]){
            result = YES;
            *stop= YES;
        }

    }];
    return result;
}
// 检查摄像头是否支持录像
- (BOOL) doesCameraSupportShootingVideos{
    return [self cameraSupportsMedia:(NSString *)kUTTypeMovie sourceType:UIImagePickerControllerSourceTypeCamera];


}
// 检查摄像头是否支持拍照
- (BOOL) doesCameraSupportTakingPhotos{
    return [self cameraSupportsMedia:( NSString *)kUTTypeImage sourceType:UIImagePickerControllerSourceTypeCamera];
}
#pragma mark - 相册文件选取相关
// 相册是否可用
- (BOOL) isPhotoLibraryAvailable{
    return [UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypePhotoLibrary];
}
// 是否可以在相册中选择视频
- (BOOL) canUserPickVideosFromPhotoLibrary{
    return [self cameraSupportsMedia:( NSString *)kUTTypeMovie sourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}

// 是否可以在相册中选择视频
- (BOOL) canUserPickPhotosFromPhotoLibrary{
    return [self cameraSupportsMedia:( NSString *)kUTTypeImage sourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}
#pragma mark -把照片存入缓存目录
-(void)saveImage:(UIImage *)image toCachePath:(NSString *)path{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:PHOTOCACHEPATH]) {
        NSLog(@"路径不存在,创建路径");
        [fileManager createDirectoryAtPath:PHOTOCACHEPATH withIntermediateDirectories:YES attributes:nil error:nil];
    }else{
        NSLog(@"路径存在");
    }

    [UIImageJPEGRepresentation(image, 1) writeToFile:path atomically:YES];
}
#pragma mark -把视频i写入缓存
-(void)saveVideoFromPath:(NSString *)videoPath toCachePath:(NSString *)path{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:VIDEOCACHEPATH]) {
        NSLog(@"路径不存在,创建路径");
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }else{
        NSLog(@"路径存在");
    }

    NSError *error;
    [fileManager copyItemAtPath:videoPath toPath:path error:&error];
    if (error) {
        NSLog(@"文件保存到缓存失败");
    }
}
///从缓存获取图片的方法:
-(UIImage *)getImageFromPath:(NSString *)path{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
        return [UIImage imageWithContentsOfFile:path];
    }

    return nil;
}
//上传图片和视频的时候我们一般会利用当前时间给文件命名, 方法如下
//以当前时间合成图片
-(NSString *)getImageNameBaseCurrentTime{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH-mm-ss"];
    return [[dateFormatter stringFromDate:[NSDate date]] stringByAppendingString:@".JPG"];
}
//以当前时间合成视频名称
- (NSString *)getVideoNameBaseCurrentTime {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH-mm-ss"];
    return [[dateFormatter stringFromDate:[NSDate date]] stringByAppendingString:@".MOV"];
}
//有时候需要获取视频的第一帧作为显示, 方法如下:
//获取视频的第一帧截图, 返回UIImage
//需要导入AVFoundation.h
-(UIImage *)getVideoPreViewImageWithPath:(NSURL *)videoPath{
    AVURLAsset * asset = [[AVURLAsset alloc]initWithURL:videoPath options:nil];
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc]initWithAsset:asset];
    gen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *img = [[UIImage alloc]initWithCGImage:image];
    return img;
}
#pragma mark - 懒加载
-(NSMutableArray *)uploadArray{
    if (_uploadArray == nil) {
        _uploadArray = [NSMutableArray array];
    }
    return  _uploadArray;
}
@end
