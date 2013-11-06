//
//  CAppDelegate.h
//  TilePicSplitter
//
//  Created by 马 俊 on 13-11-4.
//  Copyright (c) 2013年 马 俊. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CAppDelegate : NSObject <NSApplicationDelegate>
{
    IBOutlet NSTextField* inputPicFile;
    IBOutlet NSTextField* outputPath;
    
    IBOutlet NSImageView* imageView;
    
    IBOutlet NSTextField* outTextureName;
    IBOutlet NSTextField* outTmxName;
}

@property (assign) IBOutlet NSWindow *window;

@end
