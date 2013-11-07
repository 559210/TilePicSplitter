//
//  CAppDelegate.m
//  TilePicSplitter
//
//  Created by 马 俊 on 13-11-4.
//  Copyright (c) 2013年 马 俊. All rights reserved.
//

#define TILE_WIDTH      32
#define TILE_HEIGHT     32


#define TILE_GID_STR        "<tile gid=\"%d\"/>"
#define __TILE_ID__         "__TILE_ID__"
#define __MAP_WIDTH__       "__MAP_WIDTH__"
#define __MAP_HEIGHT__      "__MAP_HEIGHT__"
#define __TILE_WIDTH__      "__TILE_WIDTH__"
#define __TILE_HEIGHT__     "__TILE_HEIGHT__"
#define __TILE_SET_NAME__   "__TILE_SET_NAME__"
#define __IMAGE_WIDTH__     "__IMAGE_WIDTH__"
#define __IMAGE_HEIGHT__    "__IMAGE_HEIGHT__"
#define __IMAGE_NAME__      "__IMAGE_NAME__"

#define UD_OUTPUT_PATH      "OUTPUT_PATH"
#define UD_INPUT_PIC        "INPUT_PIC"
#define UD_TEXTURE_NAME     "TEXTURE_NAME"
#define UD_TMX_NAME         "TMX_NAME"
#define UD_OLD_TEXTURE_PATH "OLD_TEXTURE_PATH"
#define UD_GRID_WIDTH       "GRID_WIDTH"
#define UD_GRID_HEIGHT      "GRID_HEIGHT"

#import "CAppDelegate.h"
#import "CMyImage.h"


@implementation CAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    NSString* str;
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    
    str = [ud objectForKey:@UD_OUTPUT_PATH];
    if (nil != str) outputPath.stringValue = str;
    str = [ud objectForKey:@UD_INPUT_PIC];
    if (nil != str) inputPicFile.stringValue = str;
    str = [ud objectForKey:@UD_TEXTURE_NAME];
    if (nil != str) outTextureName.stringValue = str;
    str = [ud objectForKey:@UD_TMX_NAME];
    if (nil != str) outTmxName.stringValue = str;
    
    str = [ud objectForKey:@UD_OLD_TEXTURE_PATH];
    if (nil != str)
    {
        self.existTexture = [[NSImage alloc] initWithContentsOfFile:str];
        if (self.existTexture != nil)
        {
            [imageView setImage:self.existTexture];
        }
    }
    
    str = [ud objectForKey:@UD_GRID_WIDTH];
    if (nil != str)
    {
        gridWidth.stringValue = str;
    }
    else
    {
        gridWidth.intValue = TILE_WIDTH;
    }
    
    str = [ud objectForKey:@UD_GRID_HEIGHT];
    if (nil != str)
    {
        gridHeight.stringValue = str;
    }
    else
    {
        gridHeight.intValue = TILE_HEIGHT;
    }
    
    self.altas = [NSMutableArray array];
}


- (IBAction)onClose:(id)sender
{
    
}



-(BOOL)slipPic
{
    int w = gridWidth.intValue;
    int h = gridWidth.intValue;
    
    if (![self loadOldTexture:w H:h])
    {
        return NO;
    }
    
    NSImage* img = [[NSImage alloc] initWithContentsOfFile:inputPicFile.stringValue];
    if (!img) return NO;
    
    NSData  * tiffData = [img TIFFRepresentation];
    if (!tiffData) return NO;
    
    NSBitmapImageRep* rep = [NSBitmapImageRep imageRepWithData:tiffData];
    if (!rep) return NO;
    

    
    int wCount = (int)rep.pixelsWide / w;
    int hCount = (int)rep.pixelsHigh / h;
    if (wCount < 0 || hCount < 0) return NO;
    
    NSMutableArray* altas = [NSMutableArray array];
    NSMutableArray* dict = [NSMutableArray array];
    
    int x, y;
    for (y = 0; y < hCount; ++y)
    {
        for (x = 0; x < wCount; ++x)
        {
            @autoreleasepool {
                NSImage* outImg = [[NSImage alloc] initWithSize:NSMakeSize(w, h)];
                if (!outImg) return NO;
                [outImg lockFocus];
                [img drawInRect:NSMakeRect(0, 0, w, h) fromRect:NSMakeRect(x * w, rep.pixelsHigh - (y + 1) * h, w, h) operation:NSCompositeCopy fraction:1.f];
                [outImg unlockFocus];
                
                CMyImage* mi = [[CMyImage alloc] initWithNSImage:outImg];
                
                if ([altas count] == 0)
                {
                    [altas addObject:mi];
                    [dict addObject:[NSNumber numberWithInt:0]];
                }
                else
                {
                    int i;
                    for (i = 0; i < (int)[altas count]; ++i)
                    {
                        CMyImage* i1 = [altas objectAtIndex:i];
                        if ([self compareImg:i1 MI2:mi])
                        {
                            break;
                        }
                    }
                    if (i < [altas count])
                    {
                        [dict addObject:[NSNumber numberWithInt:i]];
                    }
                    else
                    {
                        [altas addObject:mi];
                        [dict addObject:[NSNumber numberWithInt:(int)[altas count]-1]];
                    }
                }
            
            }
        }
    }
    
    // 拼图
    
    int count = (int)[altas count];
    int f = (int)ceilf(sqrtf(count));
    NSSize sz = NSMakeSize(w * f, h * f);
    NSImage* oi = [[NSImage alloc] initWithSize:sz];

    [oi lockFocus];
    int i = 0;
    for (CMyImage* mi in altas)
    {
        y = i / f;
        x = i - y * f;
        [mi.img drawInRect:NSMakeRect(x * w, sz.height - (y + 1) * h, w, h) fromRect:NSMakeRect(0, 0, w, h) operation:NSCompositeCopy fraction:1.f];
        ++i;
    }
    [oi unlockFocus];

    NSData* outTiffData = [oi TIFFRepresentation];
    if (!outTiffData) return NO;

    NSBitmapImageRep* outRep = [NSBitmapImageRep imageRepWithData:outTiffData];
    if (!outRep) return NO;

    NSData* imageData = [outRep representationUsingType:NSPNGFileType properties:nil];
    if (!imageData) return NO;
    NSString* filename = [NSString stringWithFormat:@"%@%@.png", outputPath.stringValue, outTextureName.stringValue];
    if (![imageData writeToFile:filename options:NSDataWritingAtomic error:nil]) return NO;
 
    // 导出tmx xml文件
    NSBundle* myBundle = [NSBundle mainBundle];
    NSString* myImage = [myBundle pathForResource:@"template" ofType:@"tmx"];
    
    NSStringEncoding enc;
    NSString* tempStr = [NSString stringWithContentsOfFile:myImage usedEncoding:&enc error:nil];

    if (!tempStr) return NO;
    
    NSString* tile_gid = [NSString string];
    for (NSNumber* gid in dict)
    {
        @autoreleasepool {
            NSString* pice = [NSString stringWithFormat:@TILE_GID_STR, gid.intValue+1];
            tile_gid = [tile_gid stringByAppendingString:pice];
        }
    }
    
    tempStr = [tempStr stringByReplacingOccurrencesOfString:@__MAP_WIDTH__ withString:[NSString stringWithFormat:@"%d", wCount]];
    tempStr = [tempStr stringByReplacingOccurrencesOfString:@__MAP_HEIGHT__ withString:[NSString stringWithFormat:@"%d", hCount]];
    
    tempStr = [tempStr stringByReplacingOccurrencesOfString:@__TILE_WIDTH__ withString:[NSString stringWithFormat:@"%d", w]];
    tempStr = [tempStr stringByReplacingOccurrencesOfString:@__TILE_HEIGHT__ withString:[NSString stringWithFormat:@"%d", h]];

    tempStr = [tempStr stringByReplacingOccurrencesOfString:@__IMAGE_WIDTH__ withString:[NSString stringWithFormat:@"%d", (int)sz.width]];
    tempStr = [tempStr stringByReplacingOccurrencesOfString:@__IMAGE_HEIGHT__ withString:[NSString stringWithFormat:@"%d", (int)sz.height]];

    tempStr = [tempStr stringByReplacingOccurrencesOfString:@__IMAGE_NAME__ withString:[NSString stringWithFormat:@"%@.png", outTextureName.stringValue]];
    
    tempStr = [tempStr stringByReplacingOccurrencesOfString:@__TILE_ID__ withString:tile_gid];

    NSString* tmxFilename = [NSString stringWithFormat:@"%@%@.tmx", outputPath.stringValue, outTmxName.stringValue];
    [tempStr writeToFile:tmxFilename atomically:TRUE encoding:NSUTF8StringEncoding error:nil];
    return YES;
}



- (BOOL)compareImg:(CMyImage*)mi1  MI2:(CMyImage*)mi2
{
    unsigned char* d1 = [mi1 getData];
    unsigned char* d2 = [mi2 getData];
    NSInteger len1 = [mi1 getDataLen];
    NSInteger len2 = [mi2 getDataLen];
    
    NSInteger w = mi1.rep.pixelsWide;
    NSInteger h = mi1.rep.pixelsHigh;
    
    if (w != mi2.rep.pixelsWide ||
        h != mi2.rep.pixelsHigh ||
        mi1.rep.bitmapFormat != mi2.rep.bitmapFormat ||
        len1 != len2)
    {
        return NO;
    }
    
    NSInteger i;
    for (i = 0; i < len1; ++i)
    {
        if (d1[i] - d2[i] > 2) return NO;
    }
    
    
    return YES;
}


//- (BOOL)compareImg:(NSString*)filename1 FILENAME2:(NSString*)filename2
//{
//    CMyImage* mi1 = [[CMyImage alloc] initWithFileName:filename1];
//    CMyImage* mi2 = [[CMyImage alloc] initWithFileName:filename2];
//    
//    if ([self compareImg:mi1 MI2:mi2])
//    {
//        return YES;
//    }
//    
//    return NO;
//}


- (IBAction)onLoadInputBtn:(id)sender
{
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:NO];
    [panel setAllowedFileTypes:[NSArray arrayWithObjects:@"png", @"bmp", nil]];
    if ([outputPath.stringValue length] > 0)
    {
        NSURL* url = [NSURL fileURLWithPath:outputPath.stringValue isDirectory:YES];
        if (url)
        {
            [panel setDirectoryURL:url];
        }
    }
    if (NSFileHandlingPanelOKButton == [panel runModal])
    {
        inputPicFile.stringValue = [panel.URL relativePath];
        NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
        [ud setObject:inputPicFile.stringValue forKey:@UD_INPUT_PIC];
    }
}



- (IBAction)onOutDir:(id)sender
{
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:NO];
    [panel setCanChooseDirectories:YES];
    if ([outputPath.stringValue length] > 0)
    {
        NSURL* url = [NSURL fileURLWithPath:outputPath.stringValue isDirectory:YES];
        if (url)
        {
            [panel setDirectoryURL:url];
        }
    }
    if (NSFileHandlingPanelOKButton == [panel runModal])
    {
        outputPath.stringValue = [panel.URL relativePath];
        
        NSString* end = [outputPath.stringValue substringFromIndex:[outputPath.stringValue length]-1];
        if (![end isEqualToString:@"/"])
        {
            outputPath.stringValue = [outputPath.stringValue stringByAppendingString:@"/"];
        }
        
        NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
        [ud setObject:outputPath.stringValue forKey:@UD_OUTPUT_PATH];
    }
}



- (IBAction)onStart:(id)sender
{
    if (gridWidth.intValue <= 0 ||
        gridHeight.intValue <= 0)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"GridWidth and GridHeight must be set!"];
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
        return;
    }
    
    if ([inputPicFile.stringValue length] == 0 ||
        [outputPath.stringValue length] == 0)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Path can't be null"];
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
        return;
    }
    
    BOOL isDir;
    NSFileManager* fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:inputPicFile.stringValue isDirectory:&isDir] ||
        ![fm fileExistsAtPath:outputPath.stringValue isDirectory:&isDir])
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"input file or output Path are not valid"];
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
        return;
    }
    
    NSString* end = [outputPath.stringValue substringFromIndex:[outputPath.stringValue length]-1];
    if (![end isEqualToString:@"/"])
    {
        outputPath.stringValue = [outputPath.stringValue stringByAppendingString:@"/"];
    }
    
    if ([outTextureName.stringValue length] == 0 ||
        [outTmxName.stringValue length] == 0)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"texture or tmx filename must be set"];
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
        return;
    }
    
    NSString* ext = [outTextureName.stringValue pathExtension];
    if ([ext length] > 0)
    {
        outTextureName.stringValue = [outTextureName.stringValue substringToIndex:[outTextureName.stringValue length] - [ext length] - 1];
    }
    
    ext = [outTmxName.stringValue pathExtension];
    if ([ext length] > 0)
    {
        outTmxName.stringValue = [outTmxName.stringValue substringToIndex:[outTmxName.stringValue length] - [ext length] - 1];
    }
    
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:outputPath.stringValue forKey:@UD_OUTPUT_PATH];
    [ud setObject:inputPicFile.stringValue forKey:@UD_INPUT_PIC];
    [ud setObject:outTextureName.stringValue forKey:@UD_TEXTURE_NAME];
    [ud setObject:outTmxName.stringValue forKey:@UD_TMX_NAME];
    [ud setObject:gridWidth forKey:@UD_GRID_WIDTH];
    [ud setObject:gridHeight forKey:@UD_GRID_HEIGHT];
    
    if ([self slipPic])
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"DONE!"];
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
    }
    else
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Failed!"];
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
    }
}



-(IBAction)onLoadExistTexture:(id)sender
{
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:NO];
    [panel setAllowedFileTypes:[NSArray arrayWithObjects:@"png", nil]];
    if ([outputPath.stringValue length] > 0)
    {
        NSURL* url = [NSURL fileURLWithPath:outputPath.stringValue isDirectory:YES];
        if (url)
        {
            [panel setDirectoryURL:url];
        }
    }
    if (NSFileHandlingPanelOKButton == [panel runModal])
    {
        self.existTexture = [[NSImage alloc] initWithContentsOfURL:panel.URL];
        if (!self.existTexture)
        {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"Can't load the texture!"];
            [alert addButtonWithTitle:@"OK"];
            [alert runModal];
            return;
        }
        
        [imageView setImage:self.existTexture];
        
        NSString* str = [panel.URL relativePath];
        NSArray* pc = [str pathComponents];
        NSString* ext = [str pathExtension];
        str = [pc objectAtIndex:[pc count] - 1];
        if ([ext length] > 0)
        {
            outTextureName.stringValue = [str substringToIndex:[str length] - [ext length] - 1];
        }
        
        NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
        [ud setObject:[panel.URL relativePath] forKey:@UD_OLD_TEXTURE_PATH];
        [ud setObject:outTextureName.stringValue forKey:@UD_TEXTURE_NAME];
    }
}


-(BOOL)loadOldTexture : (int)w H:(int)h
{
    if (_existTexture == nil)
    {
        return YES;
    }
    [_altas removeAllObjects];
    NSData  * tiffData = [_existTexture TIFFRepresentation];
    if (!tiffData) return NO;
    
    NSBitmapImageRep* rep = [NSBitmapImageRep imageRepWithData:tiffData];
    if (!rep) return NO;
    
    int wCount = (int)rep.pixelsWide / w;
    int hCount = (int)rep.pixelsHigh / h;
    if (wCount < 0 || hCount < 0) return NO;

    
    int x, y;
    for (y = 0; y < hCount; ++y)
    {
        for (x = 0; x < wCount; ++x)
        {
            @autoreleasepool {
                NSImage* outImg = [[NSImage alloc] initWithSize:NSMakeSize(w, h)];
                if (!outImg) return NO;
                [outImg lockFocus];
                [_existTexture drawInRect:NSMakeRect(0, 0, w, h) fromRect:NSMakeRect(x * w, rep.pixelsHigh - (y + 1) * h, w, h) operation:NSCompositeCopy fraction:1.f];
                [outImg unlockFocus];
                
                CMyImage* mi = [[CMyImage alloc] initWithNSImage:outImg];
                
                [_altas addObject:mi];
            }
        }
    }

    return YES;
}


-(IBAction)onClearExistTexture:(id)sender
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud removeObjectForKey:@UD_OLD_TEXTURE_PATH];
    
    [imageView setImage:nil];
    self.existTexture = nil;

}

@end
