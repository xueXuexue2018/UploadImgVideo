//
//  UploadModel.h
//  上传图片视频
//
//  Created by juntuo on 2018/10/24.
//  Copyright © 2018 juntuo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UploadModel : NSObject
@property(nonatomic,strong)NSString *path;
@property(nonatomic,strong)NSString *type;
@property(nonatomic,strong)NSString *name;
@property(nonatomic,assign)BOOL isUploaded;
@end

NS_ASSUME_NONNULL_END
