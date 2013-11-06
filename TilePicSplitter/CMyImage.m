//
//  CMyImage.m
//  TilePicSplitter
//
//  Created by 马 俊 on 13-11-5.
//  Copyright (c) 2013年 马 俊. All rights reserved.
//

#import "CMyImage.h"

@implementation CMyImage


-(id)initWithFileName:(NSString*)filename
{
    id obj = [super init];
    
    self.img = [[NSImage alloc] initWithContentsOfFile:filename];
    
    if (!_img) return nil;
    
    NSData  * tiffData = [_img TIFFRepresentation];
    if (!tiffData) return nil;
    
    _rep = [NSBitmapImageRep imageRepWithData:tiffData];
    if (!_rep) return nil;

    self.filename = filename;

    return obj;
}



-(id)initWithNSImage:(NSImage*)img
{
    id obj = [super init];
    
    self.img = img;
    
    NSData  * tiffData = [_img TIFFRepresentation];
    if (!tiffData) return nil;
    
    _rep = [NSBitmapImageRep imageRepWithData:tiffData];
    if (!_rep) return nil;
    
    return obj;
}




-(NSInteger)getDataLen
{
    NSInteger bpp = [_rep bitsPerPixel];

    NSInteger w = _rep.pixelsWide;
    NSInteger h = _rep.pixelsHigh;
    
    return (bpp / 8) * w * h;
}



-(unsigned char*)getData
{
    return [_rep bitmapData];
}

@end
