/*
 * Copyright 2012-present Pixate, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

//
//  PXUISearchBar.m
//  Pixate
//
//  Created by Paul Colton on 10/11/12.
//  Copyright (c) 2012 Pixate, Inc. All rights reserved.
//

#import "PXUISearchBar.h"

#import "UIView+PXStyling.h"
#import "UIView+PXStyling-Private.h"
#import "PXStylingMacros.h"

#import "PXOpacityStyler.h"
#import "PXLayoutStyler.h"
#import "PXTransformStyler.h"
#import "PXFillStyler.h"
#import "PXBoxShadowStyler.h"
#import "PXTextContentStyler.h"
#import "PXGenericStyler.h"
#import "PXAnimationStyler.h"
#import "PXTextShadowStyler.h"
#import "PXUtils.h"
#import "PXFontStyler.h"
#import "PXBorderStyler.h"
#import "PXShapeStyler.h"
#import "PXVirtualStyleableControl.h"
static const char STYLE_CHILDREN;


@implementation PXUISearchBar

+ (void)initialize
{
    if (self != PXUISearchBar.class)
        return;
    
    [UIView registerDynamicSubclass:self withElementName:@"search-bar"];
}


- (NSArray *)pxStyleChildren
{
    if (!objc_getAssociatedObject(self, &STYLE_CHILDREN))
    {
        __weak PXUISearchBar *weakSelf = self;
        
        //
        // textLabel
        //
        PXVirtualStyleableControl* textField = [[PXVirtualStyleableControl alloc] initWithParent:self elementName:@"text-field" viewStyleUpdaterBlock:^(PXRuleSet *ruleSet, PXStylerContext *context) {
            // nothing for now
        }];
        
        textField.layer = [PXUISearchBar findInputViewInSearchBar:self].layer;
        
        textField.viewStylers = @[
                  PXTransformStyler.sharedInstance,
                  PXLayoutStyler.sharedInstance,
                  PXOpacityStyler.sharedInstance,
                  
                  PXShapeStyler.sharedInstance,
                  PXFillStyler.sharedInstance,
                  
                  [[PXFillStyler alloc] initWithCompletionBlock:^(id control, PXFillStyler *styler, PXStylerContext *context) {
                      UIColor *backgroundColor = context.color;
                      if (backgroundColor)
                      {
                          UITextField *view = (UITextField*)[PXUISearchBar findInputViewInSearchBar:weakSelf];
                          [view setBackgroundColor:backgroundColor];
                      }
                      
                  }],
                  
                  [[PXFontStyler alloc] initWithCompletionBlock:^(id control, PXFontStyler *styler, PXStylerContext *context) {
                      UIFont *font = context.font;
                      if (font)
                      {
                          UITextField *view = (UITextField*)[PXUISearchBar findInputViewInSearchBar:weakSelf];
                          [view setFont:context.font];
                      }
                      
                  }],
                  
                  [[PXGenericStyler alloc] initWithHandlers: @{
                    @"corner-radius" : ^(PXDeclaration *declaration, PXStylerContext *context) {
                      UITextField *inputView = (UITextField*)[PXUISearchBar findInputViewInSearchBar:weakSelf];
                      CGFloat radius = declaration.floatValue;
                      inputView.layer.cornerRadius = radius;
                    }
                       }],
                  ];

        NSArray *styleChildren = @[textField];
        
        objc_setAssociatedObject(self, &STYLE_CHILDREN, styleChildren, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return objc_getAssociatedObject(self, &STYLE_CHILDREN);
}

- (NSArray *)viewStylers
{
    static __strong NSArray *stylers = nil;
	static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        stylers = @[
            PXTransformStyler.sharedInstance,
            PXLayoutStyler.sharedInstance,

            [[PXOpacityStyler alloc] initWithCompletionBlock:^(PXUISearchBar *view, PXOpacityStyler *styler, PXStylerContext *context) {
                [view px_setTranslucent:(context.opacity < 1.0) ? YES : NO];
            }],
            
            PXFillStyler.sharedInstance,
            PXBoxShadowStyler.sharedInstance,

            [[PXTextShadowStyler alloc] initWithCompletionBlock:^(PXUISearchBar *view, PXTextShadowStyler *styler, PXStylerContext *context) {
                PXShadow *shadow = context.textShadow;
                NSMutableDictionary *currentTextAttributes = [NSMutableDictionary dictionaryWithDictionary:[view scopeBarButtonTitleTextAttributesForState:UIControlStateNormal]];

                NSShadow *nsShadow = [[NSShadow alloc] init];
                
                nsShadow.shadowColor = shadow.color;
                nsShadow.shadowOffset = CGSizeMake(shadow.horizontalOffset, shadow.verticalOffset);
                nsShadow.shadowBlurRadius = shadow.blurDistance;
                
                [currentTextAttributes setObject:nsShadow forKey:NSShadowAttributeName];

                [view px_setScopeBarButtonTitleTextAttributes:currentTextAttributes forState:UIControlStateNormal];
            }],

            [[PXTextContentStyler alloc] initWithCompletionBlock:^(PXUISearchBar *view, PXTextContentStyler *styler, PXStylerContext *context) {
                [view px_setText: context.text];
            }],

            
            [[PXGenericStyler alloc] initWithHandlers: @{

            @"-ios-tint-color" : ^(PXDeclaration *declaration, PXStylerContext *context) {
                PXUISearchBar *view = (PXUISearchBar *)context.styleable;
                UIColor *color = declaration.colorValue;
                [view px_setTintColor:color];
            },

             @"color" : ^(PXDeclaration *declaration, PXStylerContext *context) {
                PXUISearchBar *view = (PXUISearchBar *)context.styleable;
                UIColor *color = declaration.colorValue;
                [view px_setTintColor:color];
             },

            @"separator-top-color" : ^(PXDeclaration *declaration, PXStylerContext *context) {
                PXUISearchBar *view = (PXUISearchBar *)context.styleable;
                UIColor *color = declaration.colorValue;
                
                CALayer* layer = CALayer.layer;
                layer.backgroundColor = color.CGColor;
                [view.layer addSublayer:layer];
                layer.frame = CGRectMake(0, 0, CGRectGetWidth(view.bounds), 1);
            },

            @"separator-bottom-color" : ^(PXDeclaration *declaration, PXStylerContext *context) {
                PXUISearchBar *view = (PXUISearchBar *)context.styleable;
                UIColor *color = declaration.colorValue;
                
                CALayer* layer = CALayer.layer;
                layer.backgroundColor = color.CGColor;
                [view.layer addSublayer:layer];
                layer.frame = CGRectMake(0, CGRectGetHeight(view.bounds) - 1, CGRectGetWidth(view.bounds), 1);
            },

             @"bar-style" : ^(PXDeclaration *declaration, PXStylerContext *context) {
                PXUISearchBar *view = (PXUISearchBar *)context.styleable;
                NSString *style = [declaration.stringValue lowercaseString];

                if ([style isEqualToString:@"black"])
                {
                    [view px_setBarStyle: UIBarStyleBlack];
                }
                else //if([style isEqualToString:@"default"])
                {
                    [view px_setBarStyle: UIBarStyleDefault];
                }
            },
            }],

            PXAnimationStyler.sharedInstance,
        ];
    });

	return stylers;
}

- (NSDictionary *)viewStylersByProperty
{
    static NSDictionary *map = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        map = [PXStyleUtils viewStylerPropertyMapForStyleable:self];
    });

    return map;
}

- (void)updateStyleWithRuleSet:(PXRuleSet *)ruleSet context:(PXStylerContext *)context
{
    // Background color setting
    if([PXUtils isIOS7OrGreater])
    {
        if (context.color)
        {
            [self px_setBarTintColor: context.color];
        }
        else if (context.usesImage)
        {
            [self px_setBarTintColor: [UIColor colorWithPatternImage:context.backgroundImage]];
        }
    }
    else
    {
        if (context.color)
        {
            [self px_setTintColor: context.color];
        }
        else if (context.usesImage)
        {
            [self px_setTintColor: [UIColor colorWithPatternImage:context.backgroundImage]];
        }
    }
}

+ (UIView*)findInputViewInSearchBar:(UISearchBar*) searchBar {
    UIView* resultView = nil;
    UIView* coreView = (UIView*)searchBar.subviews[0];
    if (coreView != nil) {
        for (UIView* view in coreView.subviews) {
            if ([view isKindOfClass:[UITextField class]])  {
                resultView = view;
                break;
            }
        }

    }
    
    return resultView;
}

PX_PXWRAP_1(setText, text);

PX_WRAP_1(setBarTintColor, color);
PX_WRAP_1(setTintColor, color);
PX_WRAP_1b(setTranslucent, flag);
PX_WRAP_1v(setBarStyle, UIBarStyle, style);
PX_WRAP_2v(setScopeBarButtonTitleTextAttributes, attrs, forState, UIControlState, state);

PX_LAYOUT_SUBVIEWS_OVERRIDE

@end
