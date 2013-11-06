//
//  CMyImage.h
//  TilePicSplitter
//
//  Created by 马 俊 on 13-11-5.
//  Copyright (c) 2013年 马 俊. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CMyImage : NSObject

@property (retain) NSImage* img;
@property (retain) NSBitmapImageRep* rep;
@property (retain) NSString* filename;

-(id)initWithFileName:(NSString*)filename;
-(id)initWithNSImage:(NSImage*)img;
-(NSInteger)getDataLen;
-(unsigned char*)getData;

@end
