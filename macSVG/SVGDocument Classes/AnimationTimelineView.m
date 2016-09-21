//
//  AnimationTimelineView.m
//  macSVG
//
//  Created by Douglas Ward on 12/17/11.
//  Copyright © 2016 ArkPhone LLC. All rights reserved.
//

#import "AnimationTimelineView.h"
#import "AnimationTimelineElement.h"
#import "AnimationTimescaleView.h"
#import "AnimationTimespan.h"
#import "MacSVGDocumentWindowController.h"
#import "MacSVGDocument.h"
#import "SynchroScrollView.h"
#import "TimelineLabelsTableViewDelegate.h"

//#import "SMILTime.h"
//#import "SMILTimeContainer.h"
//#import "SVGSMILElement.h"

//#define topItemYOffset 54

//#define timelineSeconds 30.0f

@implementation AnimationTimelineView

//==================================================================================
//	dealloc
//==================================================================================

- (void)dealloc
{
    self.timelineElementsArray = NULL;

    self.whiteColor = NULL;
    self.blackColor = NULL;
    self.lightGrayColor = NULL;
    self.grayColor = NULL;
    self.darkGrayColor = NULL;
    self.redColor = NULL;
    self.greenColor = NULL;
    self.blueColor = NULL;
    self.cyanColor = NULL;
    self.magentaColor = NULL;
    self.yellowColor = NULL;
    self.lightBlueColor = NULL;
    self.lightGreenColor = NULL;
    self.lighterGreenColor = NULL;
    self.lightYellowColor = NULL;
    
    self.separationSet = NULL;
    self.whitespaceSet = NULL;
}

//==================================================================================
//	initIvars
//==================================================================================

- (void)initIvars
{
    self.timeValue = 0;
    self.pixelsPerSecond = 100.0f;
    self.timelineMaxSeconds = 60.0f;

    self.whiteColor = [NSColor whiteColor];
    self.blackColor = [NSColor blackColor];
    self.lightGrayColor = [NSColor lightGrayColor];
    self.grayColor = [NSColor grayColor];
    self.darkGrayColor = [NSColor darkGrayColor];
    self.redColor = [NSColor redColor];
    self.greenColor = [NSColor greenColor];
    self.blueColor = [NSColor blueColor];
    self.cyanColor = [NSColor cyanColor];
    self.magentaColor = [NSColor magentaColor];
    self.yellowColor = [NSColor yellowColor];
    self.lightBlueColor = [NSColor colorWithCalibratedRed:0.5 green:0.5 blue:1.0 alpha:1.0];
    self.lightGreenColor = [NSColor colorWithCalibratedRed:0.5 green:1.0 blue:0.5 alpha:1.0];
    self.lighterGreenColor = [NSColor colorWithCalibratedRed:0.8 green:1.0 blue:0.8 alpha:1.0];
    self.lightYellowColor = [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.5 alpha:1.0];
    
    self.timelineElementsArray = [[NSMutableArray alloc] init];

    self.separationSet = [NSCharacterSet characterSetWithCharactersInString:@" ,;"];
    self.whitespaceSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];

    //NSWindow * myWindow = self.window;

    NSNotificationCenter * aNotificationCenter = [NSNotificationCenter defaultCenter]; 
        
    //[aNotificationCenter addObserver:self selector:@selector(windowResized:) 
    //        name:NSApplicationWillBecomeActiveNotification object:nil]; 
    //[aNotificationCenter addObserver:self selector:@selector(windowResized:) 
    //        name:NSWindowDidResizeNotification object:myWindow]; 

    [aNotificationCenter addObserver:self
            selector:@selector(viewResized:)
            name:NSViewFrameDidChangeNotification
            object:self];
}

//==================================================================================
//	initWithFrame:
//==================================================================================

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        [self initIvars];
    }
    
    return self;
}

//==================================================================================
//	initWithCoder:
//==================================================================================

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code here.
        [self initIvars];
    }
    
    return self;
}

//==================================================================================
//	allocFloatString:
//==================================================================================

- (NSMutableString *)allocFloatString:(float)aFloat
{
    NSMutableString * aString = [[NSMutableString alloc] initWithFormat:@"%f", aFloat];

    BOOL continueTrim = YES;
    while (continueTrim == YES)
    {
        NSUInteger stringLength = [aString length];
        
        if (stringLength <= 1)
        {
            continueTrim = NO;
        }
        else
        {
            unichar lastChar = [aString characterAtIndex:(stringLength - 1)];
            
            if (lastChar == '0')
            {
                NSRange deleteRange = NSMakeRange(stringLength - 1, 1);
                [aString deleteCharactersInRange:deleteRange];
            }
            else if (lastChar == '.')
            {
                NSRange deleteRange = NSMakeRange(stringLength - 1, 1);
                [aString deleteCharactersInRange:deleteRange];
                continueTrim = NO;
            }
            else
            {
                continueTrim = NO;
            }
        }
    }
    return aString;
}

//==================================================================================
//	allocTimeComponentsDictionary:
//==================================================================================

- (NSMutableDictionary *)allocTimeComponentsDictionary:(NSString *)beginTime
{
    NSMutableDictionary * resultDictionary = [[NSMutableDictionary alloc] init];
    
    NSString * trimmedBeginTime = [beginTime stringByTrimmingCharactersInSet:self.whitespaceSet];

    NSUInteger stringLength = [trimmedBeginTime length];
    
    if (stringLength == 0)
    {
        NSLog(@"allocTimeComponentsDictionary - Error: stringLength is zero");
    }
    
    //NSLog(@"allocTimeComponentsDictionary beginTime=%@", beginTime);
    
    unichar firstChar = [trimmedBeginTime characterAtIndex:0];
    
    BOOL isAbsoluteTime = NO;
    
    if (firstChar >= '0')
    {
        if (firstChar <= '9')
        {
            isAbsoluteTime = YES;
        }
    }
    
    NSUInteger timeQualifierOffset = NSNotFound;
    NSUInteger timeQualifierOffsetCount = 0;
    
    // scan the string
    for (int i = 0; i < stringLength; i++)
    {
        unichar aChar = [trimmedBeginTime characterAtIndex:i];
        if (isAbsoluteTime == YES)
        {
            if ((aChar < '0') || (aChar > '9')) 
            {
                if (aChar != '.')
                {
                    timeQualifierOffset = i;
                    timeQualifierOffsetCount++;
                }
            }
        }
        else
        {
            if (aChar == '.')
            {
                timeQualifierOffset = i;
                timeQualifierOffsetCount++;
                break;
            }
        }
    }
    
    /*
    if (timeQualifierOffsetCount > 2)
    {
        NSLog(@"Error - timeQualifierOffsetCount > 2, %@", beginTime);
    }
    else if (timeQualifierOffsetCount == 2)
    {
        //NSLog(@"Error - timeQualifierOffsetCount > 1, %@", beginTime);
        if (isAbsoluteTime == NO)
        {
            // probably an event and syncbase offset
            NSString * eventID = [trimmedBeginTime substringToIndex:(timeQualifierOffset)];
            NSString * eventQualifier = [trimmedBeginTime substringFromIndex:(timeQualifierOffset + 1)];

            [resultDictionary setObject:@"event" forKey:@"method"];
            [resultDictionary setObject:eventID forKey:@"eventID"];
            [resultDictionary setObject:eventQualifier forKey:@"eventQualifier"];
        }
        else
        {
            NSLog(@"Error - invalid timeQualifierOffsetCount = 2, %@", beginTime);
        }
    }
    else
    */
    
    if (timeQualifierOffsetCount == 1)
    {
        if (isAbsoluteTime == YES)
        {
            //NSRange valueRange = NSMakeRange(0, timeQualifierOffset - 1);
            NSString * valueString = [trimmedBeginTime substringToIndex:timeQualifierOffset];
            
            NSUInteger valueStringLength = [valueString length];
            if (valueStringLength > 1)
            {
                unichar lastChar = [valueString characterAtIndex:(valueStringLength - 1)];

                if ((lastChar >= '0') && (lastChar <= '9'))
                {
                    valueString = [NSString stringWithFormat:@"%@s", valueString];
                }
            }
                
            NSString * timeUnit = [trimmedBeginTime substringFromIndex:timeQualifierOffset];
            
            [resultDictionary setObject:@"absoluteTime" forKey:@"method"];
            [resultDictionary setObject:valueString forKey:@"value"];
            [resultDictionary setObject:timeUnit forKey:@"timeUnit"];
        }
        else
        {
            NSString * eventID = [trimmedBeginTime substringToIndex:(timeQualifierOffset)];
            NSString * eventQualifier = [trimmedBeginTime substringFromIndex:(timeQualifierOffset + 1)];

            [resultDictionary setObject:@"event" forKey:@"method"];
            [resultDictionary setObject:eventID forKey:@"eventID"];
            [resultDictionary setObject:eventQualifier forKey:@"eventQualifier"];
        }
    }
    else if (timeQualifierOffsetCount == 0)
    {
        if (isAbsoluteTime == YES)
        {
            //NSString * valueString = [trimmedBeginTime substringToIndex:timeQualifierOffset];
            NSString * valueString = trimmedBeginTime;

            [resultDictionary setObject:@"absoluteTime" forKey:@"method"];
            [resultDictionary setObject:valueString forKey:@"value"];
            [resultDictionary setObject:@"s" forKey:@"timeUnit"];
        }
    }
    
    return resultDictionary;
}

//==================================================================================
//	setPlayHeadPosition:
//==================================================================================

- (void)setPlayHeadPosition:(float)newTimeValue
{
    self.timeValue = newTimeValue;
    
    [self.animationTimescaleView setPlayHeadPosition];
}

//==================================================================================
//	findAnimationElementsInElement:
//==================================================================================

- (void)findAnimationElementsInElement:(NSXMLElement *)aElement animationElementsArray:(NSMutableArray *)animationElementsArray
{
    // recursive search for elements
    NSString * tagName = [aElement name];
    
    BOOL isAnimationElement = NO;
    
    if ([tagName isEqualToString:@"set"] == YES)
    {
        isAnimationElement = YES;
    } 
    
    if ([tagName isEqualToString:@"animate"] == YES)
    {
        isAnimationElement = YES;
    } 
    
    if ([tagName isEqualToString:@"animateColor"] == YES)
    {
        isAnimationElement = YES;
    } 
    
    if ([tagName isEqualToString:@"animateMotion"] == YES)
    {
        isAnimationElement = YES;
    } 
    
    if ([tagName isEqualToString:@"animateTransform"] == YES)
    {
        isAnimationElement = YES;
    }
    
    if (isAnimationElement == YES)
    {
        NSMutableDictionary * animationElementDictionary = [[NSMutableDictionary alloc] init];
        
        [animationElementDictionary setObject:aElement forKey:@"element"];
        [animationElementDictionary setObject:tagName forKey:@"tagName"];
        
        NSMutableDictionary * attributesDictionary = [[NSMutableDictionary alloc] init];
    
        NSArray * attributesArray = [aElement attributes];
        
        for (NSXMLNode * aNode in attributesArray)
        {
            NSString * attributeName = [aNode name];
            NSString * attributeString = [aNode stringValue];
            
            NSString * attributeValue = [[NSString alloc] initWithString:attributeString];
            [attributesDictionary setObject:attributeValue forKey:attributeName];
        }
        
        [animationElementDictionary setObject:attributesDictionary forKey:@"attributes"];

        [animationElementsArray addObject:animationElementDictionary];
    }
    
    NSUInteger childCount = [aElement childCount];
    
    int i;
    for (i = 0; i < childCount; i++) 
    {
        NSXMLNode * aNode = [aElement childAtIndex:i];
        NSXMLNodeKind nodeKind = [aNode kind];
        if (nodeKind == NSXMLElementKind)
        {
            NSXMLElement * childElement = (NSXMLElement *)aNode;
            [self findAnimationElementsInElement:childElement animationElementsArray:animationElementsArray]; // recursive call
        }
    }
}

//==================================================================================
//	indexOfAnimationElementInTimeline
//==================================================================================

- (NSUInteger) indexOfAnimationElementInTimeline:(NSMutableDictionary *)animationElementDictionary
{
    NSUInteger result = NSNotFound;
    
    NSMutableDictionary * attributesDictionary = [animationElementDictionary objectForKey:@"attributes"];
    NSString * searchMacsvgid = [attributesDictionary objectForKey:@"macsvgid"];
    
    NSUInteger timelineElementsArrayCount = [self.timelineElementsArray count];
    
    if (timelineElementsArrayCount > 0)
    {
        BOOL continueSearch = YES;
        NSUInteger timelineElementIndex = 0;
        while (continueSearch == YES) 
        {
            AnimationTimelineElement * animationTimelineElement = [self.timelineElementsArray
                    objectAtIndex:timelineElementIndex];
                    
            //NSMutableDictionary * aAttributesDictionary = [itemDictionary objectForKey:@"attributes"];
            //NSString * aMacsvgid = [aAttributesDictionary objectForKey:@"macsvgid"];

            NSString * aMacsvgid = animationTimelineElement.macsvgid;
            
            if ([aMacsvgid isEqualToString:searchMacsvgid] == YES)
            {
                result = timelineElementIndex;
                continueSearch = NO;
            }
            
            timelineElementIndex++;
            
            if (timelineElementIndex >= timelineElementsArrayCount)
            {
                continueSearch = NO;
            }
        }
    }    
    
    return result;
}

//==================================================================================
//	indexOfElementIdInTimeline
//==================================================================================

- (NSUInteger) indexOfElementIdInTimeline:(NSString *)animationElementID
{
    NSUInteger result = NSNotFound;
    
    NSUInteger timelineElementsArrayCount = [self.timelineElementsArray count];
    
    if (timelineElementsArrayCount > 0)
    {
        BOOL continueSearch = YES;
        NSUInteger timelineElementIndex = 0;
        while (continueSearch == YES) 
        {
            AnimationTimelineElement * timelineElement = [self.timelineElementsArray
                    objectAtIndex:timelineElementIndex];
                    
            NSString * elementID = timelineElement.elementID;
            
            if ([elementID isEqualToString:animationElementID] == YES)
            {
                result = timelineElementIndex;
                continueSearch = NO;
            }
            
            timelineElementIndex++;
            
            if (timelineElementIndex >= timelineElementsArrayCount)
            {
                continueSearch = NO;
            }
        }
    }    
    
    return result;
}

//==================================================================================
//	timelineSort()
//==================================================================================

NSComparisonResult timelineSort(id element1, id element2, void *context)
{
    NSComparisonResult sortResult = NSOrderedSame;
    
    AnimationTimelineElement * animationElement1 = element1;
    AnimationTimelineElement * animationElement2 = element2;

    NSString * parentID1 = animationElement1.parentID;
    NSString * parentID2 = animationElement2.parentID;

    sortResult = [parentID1 compare:parentID2];
        
    if (sortResult == NSOrderedSame)
    {
        NSString * elementID1 = animationElement1.elementID;
        NSString * elementID2 = animationElement2.elementID;

        sortResult = [elementID1 compare:elementID2];
        
        if (sortResult == NSOrderedSame)
        {
            float beginSeconds1 = [element1 earliestBeginSeconds];
            float beginSeconds2 = [element2 earliestBeginSeconds];

            if (beginSeconds1 > beginSeconds2) 
            {
                sortResult = (NSComparisonResult)NSOrderedDescending;
            }
            else if (beginSeconds1 < beginSeconds2) 
            {
                sortResult = (NSComparisonResult)NSOrderedAscending;
            }
            else
            {
                sortResult = (NSComparisonResult)NSOrderedSame;
            }
        }
    }
    
    return sortResult;
}

//==================================================================================
//	durationForAnimationElement:
//==================================================================================

- (float) durationForAnimationElement:(NSMutableDictionary *)animationElementDictionary
{
    float durationTime = 0;
    
    NSMutableDictionary * attributesDictionary = [animationElementDictionary objectForKey:@"attributes"];
    
    NSString * durationAttribute = [attributesDictionary objectForKey:@"dur"];
    
    // FIXME: also needs support for 'end' time value attribute
    
    NSMutableDictionary * durationTimeDictionary = [self allocTimeComponentsDictionary:durationAttribute];
    
    NSString * timeMethod = [durationTimeDictionary objectForKey:@"method"];
    
    if ([timeMethod isEqualToString:@"absoluteTime"] == YES)
    {
        NSString * aTimeValue = [durationTimeDictionary objectForKey:@"value"];
        durationTime = [aTimeValue floatValue];
    }
    else if ([timeMethod isEqualToString:@"event"] == YES)
    {
        NSLog(@"durationForAnimationElement for event ???");
    }
    
    return durationTime;
}

//==================================================================================
//	descriptionForTagName:type:parentID:
//==================================================================================

-(NSString *)descriptionForTagName:(NSString *)tagName type:(NSString *)typeAttribute parentID:(NSString *)parentID
{
    NSMutableString * infoString = [[NSMutableString alloc] init];
            
    if ([tagName isEqualToString:@"set"] == YES)
    {
        [infoString appendString:@"Set "];
    }
    else if ([tagName isEqualToString:@"animate"] == YES)
    {
        [infoString appendString:@"Animate "];
    }
    else if ([tagName isEqualToString:@"animateColor"] == YES)
    {
        [infoString appendString:@"Color "];
    }
    else if ([tagName isEqualToString:@"animateMotion"] == YES)
    {
        [infoString appendString:@"Motion "];
    }
    else if ([tagName isEqualToString:@"animateTransform"] == YES)
    {
        if ([typeAttribute isEqualToString:@"translate"] == YES) 
        {
            [infoString appendString:@"Translate "];
        }
        else if ([typeAttribute isEqualToString:@"rotate"] == YES) 
        {
            [infoString appendString:@"Rotate "];
        }
        else if ([typeAttribute isEqualToString:@"scale"] == YES) 
        {
            [infoString appendString:@"Scale "];
        }
        else if ([typeAttribute isEqualToString:@"matrix"] == YES) 
        {
            [infoString appendString:@"Matrix "];
        }
        else
        {
            [infoString appendString:typeAttribute];
        }
    }
    
    [infoString appendString:parentID];
    
    return infoString;
}

//==================================================================================
//	addTimelineItemForElement:beginSeconds:durationSeconds:method
//==================================================================================

- (BOOL) addTimelineItemForElement:(NSMutableDictionary *)animationElementDictionary 
        beginSeconds:(NSString *)beginSeconds durationSeconds:(float)durationSeconds
        method:(NSString *)method
{
    BOOL result = NO;
    
    float beginSecondsFloat = [beginSeconds floatValue];
    
    if (beginSecondsFloat < self.timelineMaxSeconds)
    {
        BOOL isRepeatElement = NO;

        unsigned long elementIndex = [self indexOfAnimationElementInTimeline:animationElementDictionary];
        
        AnimationTimelineElement * animationTimelineElement = NULL;

        if (elementIndex != NSNotFound)
        {
            isRepeatElement = YES;  // a timeline element already exists, so a repeat
            animationTimelineElement = [self.timelineElementsArray objectAtIndex:elementIndex];
        }
        else
        {
            animationTimelineElement = [[AnimationTimelineElement alloc] init];
                        
            NSMutableDictionary * attributesDictionary = [animationElementDictionary objectForKey:@"attributes"];
            
            NSXMLElement * xmlElement = [animationElementDictionary objectForKey:@"element"];
            
            NSString * aTagName = [animationElementDictionary objectForKey:@"tagName"];
            
            NSString * aMacsvgid = [attributesDictionary objectForKey:@"macsvgid"];
            
            NSString * aElementID = @"";
            NSString * aElementIDTry = [attributesDictionary objectForKey:@"id"];
            if (aElementIDTry != NULL)
            {
                aElementID = aElementIDTry;
            }
            
            NSString * transformType = [attributesDictionary objectForKey:@"type"];
            if (transformType == NULL)
            {
                transformType = @"";
            }
            
            NSString * tagName = [[NSString alloc] initWithString:aTagName];
            NSString * macsvgid = [[NSString alloc] initWithString:aMacsvgid];
            NSString * elementID = [[NSString alloc] initWithString:aElementID];
            
            NSString * aParentTagName = @"";
            NSString * aParentMacsvgid = @"";
            NSString * aParentID = @"";
            
            NSXMLNode * parentNode = [xmlElement parent];
            if (parentNode != NULL)
            {
                NSXMLElement * parentElement = (NSXMLElement *)parentNode;
                
                aParentTagName = [parentElement name];
                
                NSXMLNode * parentMacsvgidNode = [parentElement attributeForName:@"macsvgid"];
                aParentMacsvgid = [parentMacsvgidNode stringValue];

                NSXMLNode * parentIDNode = [parentElement attributeForName:@"id"];
                if (parentIDNode != NULL)
                {
                    aParentID = [parentIDNode stringValue];
                }
                else
                {
                    aParentID = [NSString stringWithFormat:@"(%@)", aParentTagName];
                }
            }
            
            NSString * parentTagName = [[NSString alloc] initWithString:aParentTagName];
            NSString * parentMacsvgid = [[NSString alloc] initWithString:aParentMacsvgid];
            NSString * parentID = [[NSString alloc] initWithString:aParentID];

            animationTimelineElement.tagName = tagName;
            animationTimelineElement.macsvgid = macsvgid;
            animationTimelineElement.elementID = elementID;
            
            animationTimelineElement.parentTagName = parentTagName;
            animationTimelineElement.parentMacsvgid = parentMacsvgid;
            animationTimelineElement.parentID = parentID;
                        
            animationTimelineElement.elementDescription = [self descriptionForTagName:tagName type:transformType parentID:parentID];

            [self.timelineElementsArray addObject:animationTimelineElement];
            
            elementIndex = [self.timelineElementsArray count] - 1;
        }
        
        NSMutableArray * animationTimespanArray = animationTimelineElement.animationTimespanArray;
        
        BOOL duplicateTimespanExists = NO;
        
        if (animationTimespanArray != NULL)
        {
            if ([animationTimespanArray count] > 0)
            {
                 for (AnimationTimespan * animationTimespan in animationTimespanArray)
                {
                    float existingBeginSeconds = animationTimespan.beginSeconds;
                    if (beginSecondsFloat == existingBeginSeconds)
                    {
                        duplicateTimespanExists = YES;
                    }
                }
            }
        }
        
        if (duplicateTimespanExists == NO)
        {
            int colorIndex = 0;
            
            if ([method isEqualToString:@"eventTime"] == YES)
            {
                colorIndex = 2;
            }
            
            NSRect frameRect = self.frame;
            
            [animationTimelineElement addTimespanAtBegin:beginSecondsFloat dur:durationSeconds colorIndex:colorIndex
                    pixelPerSecond:self.pixelsPerSecond frameRect:frameRect rowIndex:elementIndex];
                    
            NSMutableDictionary * attributesDictionary = [animationElementDictionary objectForKey:@"attributes"];
            NSString * repeatCount = [attributesDictionary objectForKey:@"repeatCount"];
            int repeatCountValue = 0;
            if (repeatCount != NULL)
            {
                if ([repeatCount isEqualToString:@"indefinite"] == YES)
                {
                    float remainingTime = self.timelineMaxSeconds - (beginSecondsFloat + durationSeconds);
                    repeatCountValue = remainingTime / durationSeconds;
                    
                    float repeatCountFloat = remainingTime / durationSeconds;
                    if (repeatCountFloat > (float)repeatCountValue)
                    {
                        repeatCountValue++;
                    }
                }
                else
                {
                    repeatCountValue = [repeatCount intValue];
                }
                
                if (repeatCountValue > 0)
                {
                    colorIndex = 1;
                    
                    float nextBeginSecondsFloat = beginSecondsFloat + durationSeconds;
                    for (int j = 0; j < repeatCountValue; j++)
                    {
                        [animationTimelineElement addTimespanAtBegin:nextBeginSecondsFloat dur:durationSeconds colorIndex:colorIndex
                                pixelPerSecond:self.pixelsPerSecond frameRect:frameRect rowIndex:elementIndex];
                                
                        nextBeginSecondsFloat += durationSeconds;
                    }
                }
            }
           
            result = YES;
        }
    }
    else
    {
        result = NO;
    }
    
    return result;
}

//==================================================================================
//	addTimelineElement:forBeginTime:timeUnit
//==================================================================================

- (BOOL) addTimelineElement:(NSMutableDictionary *)animationElementDictionary forBeginTime:(NSString *)valueString timeUnit:(NSString *)timeUnit
{
    // for begin values specifying absolute seconds, e.g. "0s"
    BOOL result = NO;
    
    NSUInteger elementIndex = [self indexOfAnimationElementInTimeline:animationElementDictionary];
    
    if (elementIndex == NSNotFound)
    {
        float duration = [self durationForAnimationElement:animationElementDictionary];
        
        result = [self addTimelineItemForElement:animationElementDictionary 
                beginSeconds:valueString durationSeconds:duration method:@"absoluteTime"];
    }
            
    return result;  // YES if timeline item was added
}

//==================================================================================
//	addTimelineElement:forEventID:eventQualifier
//==================================================================================

- (BOOL) addTimelineElement:(NSMutableDictionary *)animationElementDictionary forEventID:(NSString *)eventID eventQualifier:(NSString *)eventQualifier
{
    // for begin values specifying an event by animation element id and qualifier, e.g. "aAnimateElement.end"
        
    BOOL result = NO;

    NSUInteger timelineIndex = [self indexOfElementIdInTimeline:eventID];
    
    if (timelineIndex != NSNotFound)
    {
        // a timeline does not exist for current element, create a new one
        float duration = [self durationForAnimationElement:animationElementDictionary];
        
        AnimationTimelineElement * animationTimelineElement = [self.timelineElementsArray objectAtIndex:timelineIndex];
        
        NSMutableArray * animationTimespanArray = animationTimelineElement.animationTimespanArray;
        
        AnimationTimespan * animationTimespan = [animationTimespanArray lastObject];
        
        float previousBeginSeconds = animationTimespan.beginSeconds;
        float previousDurationSeconds = animationTimespan.durationSeconds;
        
        float beginSeconds = 0;
        
        /*
        if ([eventQualifier isEqualToString:@"begin"] == YES)
        {
            beginSeconds = previousBeginSeconds;
        }
        else if ([eventQualifier isEqualToString:@"end"] == YES)
        {
            beginSeconds = previousBeginSeconds + previousDurationSeconds;
        }
        */
        
        NSString * syncbaseOffsetString = @"";

        NSRange beginRange = [eventQualifier rangeOfString:@"begin"];
        NSRange endRange = [eventQualifier rangeOfString:@"end"];
        if (beginRange.location == 0)
        {
            beginSeconds = previousBeginSeconds;
            
            syncbaseOffsetString = [eventQualifier stringByReplacingOccurrencesOfString:@"begin" withString:@""];
        }
        else if (endRange.location == 0)
        {
            beginSeconds = previousBeginSeconds + previousDurationSeconds;
            
            syncbaseOffsetString = [eventQualifier stringByReplacingOccurrencesOfString:@"end" withString:@""];
        }
        
        CGFloat syncbaseOffsetFloat = [syncbaseOffsetString floatValue];
        beginSeconds += syncbaseOffsetFloat;
        
        //NSLog(@"%@.%@ %@", eventID, eventQualifier, beginSecondsString);
        
        NSString * beginSecondsString = [self allocFloatString:beginSeconds];

        result = [self addTimelineItemForElement:animationElementDictionary 
                beginSeconds:beginSecondsString durationSeconds:duration method:@"eventTime"];
    }
            
    return result;
}

//==================================================================================
//	addTimelineElement:forBeginTime:beginMode:
//==================================================================================

- (BOOL)addTimelineElement:(NSMutableDictionary *)animationElementDictionary forBeginTime:(NSString *)beginTime beginMode:(NSString *)beginMode
{
    BOOL result = NO;
    
    NSMutableDictionary * timeComponentsDictionary = [self allocTimeComponentsDictionary:beginTime];

    NSString * method = [timeComponentsDictionary objectForKey:@"method"];

    if ([method isEqualToString:@"absoluteTime"] == YES)
    {
        if ([beginMode isEqualToString:@"absoluteTime"] == YES)
        {
            NSString * valueString = [timeComponentsDictionary objectForKey:@"value"];
            NSString * timeUnit = [timeComponentsDictionary objectForKey:@"timeUnit"];
            
            BOOL aResult = [self addTimelineElement:animationElementDictionary forBeginTime:valueString timeUnit:timeUnit];
            if (aResult == YES)
            {
                result = YES;
            }
        }
    }
    else
    {
        if ([beginMode isEqualToString:@"eventTime"] == YES)
        {
            NSString * eventID = [timeComponentsDictionary objectForKey:@"eventID"];
            NSString * eventQualifier = [timeComponentsDictionary objectForKey:@"eventQualifier"];

            BOOL aResult = [self addTimelineElement:animationElementDictionary forEventID:eventID eventQualifier:eventQualifier];
            if (aResult == YES)
            {
                result = YES;
            }
        }
    }
    
    return result;
}

//==================================================================================
//	addTimelineElement:beginMode
//==================================================================================

- (BOOL)addTimelineElement:(NSMutableDictionary *)animationElementDictionary beginMode:(NSString *)beginMode
{
    BOOL result = NO;
        
    //NSString * beginAttribute = [animationElementDictionary objectForKey:@"beginAttribute"];
    
    NSMutableDictionary * attributesDictionary = [animationElementDictionary objectForKey:@"attributes"];
    NSString * beginAttribute = [attributesDictionary objectForKey:@"begin"];
    
    if (beginAttribute == NULL)
    {
        beginAttribute = @"0s";
    }
    
    NSArray * beginArray = [beginAttribute componentsSeparatedByCharactersInSet:self.separationSet];
    
    for (NSString * untrimmedBeginTime in beginArray) 
    {
        NSString * beginTime = [untrimmedBeginTime stringByTrimmingCharactersInSet:self.separationSet];
    
        NSUInteger beginTimeLength = [beginTime length];
        
        if (beginTimeLength > 0)
        {
            BOOL aResult = [self addTimelineElement:animationElementDictionary 
                    forBeginTime:beginTime beginMode:beginMode];
            if (aResult == YES)
            {
                result = YES;
            }
        }
    }

    return result;
}

//==================================================================================
//	addAbsoluteTimeElementsToTimeline:
//==================================================================================

- (void)addAbsoluteTimeElementsToTimeline:(NSMutableArray *)animationElementsArray
{
    // build timelineItemsArray - first pass for absolute begin times
    NSUInteger changeCount = 0;
    BOOL continueBuild = YES;
    while (continueBuild == YES)
    {
        BOOL timelineChanged = NO;
        for (NSMutableDictionary * animationElementDictionary in animationElementsArray)
        {
            BOOL aTimelineChanged = [self addTimelineElement:animationElementDictionary beginMode:@"absoluteTime"];
            if (aTimelineChanged == YES)
            {
                timelineChanged = YES;
                changeCount++;
            }
        }
        if (timelineChanged == NO)
        {
            continueBuild = NO;
        }
        if (changeCount > 1000)
        {
            continueBuild = NO;
            NSLog(@"addAbsoluteTimeElementsToTimeline changeCount > 1000");
        }
    }
}

//==================================================================================
//	addEventElementsToTimeline:
//==================================================================================

- (void)addEventElementsToTimeline:(NSMutableArray *)animationElementsArray
{
    NSUInteger changeCount = 0;
    BOOL continueBuild = YES;
    while (continueBuild == YES)
    {
        BOOL timelineChanged = NO;
        for (NSMutableDictionary * animationElementDictionary in animationElementsArray)
        {
            BOOL aTimelineChanged = [self addTimelineElement:animationElementDictionary beginMode:@"eventTime"];
            if (aTimelineChanged == YES)
            {
                timelineChanged = YES;
                changeCount++;
            }
        }
        if (timelineChanged == NO)
        {
            continueBuild = NO;
        }
        if (changeCount > 1000)
        {
            continueBuild = NO;
            NSLog(@"addEventElementsToTimeline changeCount > 1000");
        }
    }
}

//==================================================================================
//	reorderTimelineRows
//==================================================================================

- (void)reorderTimelineRows
{
    int rowIndex = 0;
    for (AnimationTimelineElement * animationTimelineElement in self.timelineElementsArray)
    {
        NSMutableArray * animationTimespanArray = animationTimelineElement.animationTimespanArray;
        
        for (AnimationTimespan * animationTimespan in animationTimespanArray)
        {
            NSRect timespanRect = animationTimespan.timelineRect;
            
            timespanRect.origin.y = rowIndex * timelineItemHeight;
            
            animationTimespan.timelineRect = timespanRect;
        }
        
        rowIndex++;
    }
}

//==================================================================================
//	setTimelineViewSize
//==================================================================================

- (void)setTimelineViewSize
{
    [self.timescaleScrollView setSynchronizedScrollView:self.timelineScrollView];
    self.timescaleScrollView.scrollHorizontal = YES;
    
    [self.timelineScrollView setSynchronizedScrollView:self.labelScrollView];
    
    NSRect documentVisibleRect = [self.timelineScrollView documentVisibleRect];
    
    [self.labelScrollView setSynchronizedScrollView:self.timelineScrollView];
     
    NSRect frameRect = self.frame;
    
    frameRect.origin.x = 0;
    frameRect.origin.y = 0;
    
    frameRect.size.width = self.timelineMaxSeconds * self.pixelsPerSecond;
    frameRect.size.height = [self.timelineElementsArray count] * timelineItemHeight;
        
    if (frameRect.size.height < documentVisibleRect.size.height)
    {
        frameRect.size.height = documentVisibleRect.size.height;
    }
    
    [self setFrame:frameRect];
    [self setBounds:frameRect];
    
    NSRect timescaleFrameRect = self.animationTimescaleView.frame;
    timescaleFrameRect.origin.x = 0;
    timescaleFrameRect.origin.y = 0;
    timescaleFrameRect.size.width = frameRect.size.width;
    [self.animationTimescaleView setFrame:timescaleFrameRect];
    [self.animationTimescaleView setBounds:timescaleFrameRect];
}

//==================================================================================
//	viewResized
//==================================================================================

- (void)viewResized:(NSNotification *)aNotification
{
    [self setTimelineViewSize];
}

//==================================================================================
//	reloadData
//==================================================================================

- (void)reloadData
{
    // build arrays for timeline display -
    // 1) build timelineElementsArray containing all animation elements
    // 2) first pass build of timelineItemsArray for animation elements with absolute begin time
    // 3) second pass build of timelineItemsArray for animation elements with event-driven begin time
    // 4) reorder timelineItemsArray for rows in timeline display

    NSMutableArray * animationElementsArray = [[NSMutableArray alloc] init];

    MacSVGDocument * macSVGDocument = [self.macSVGDocumentWindowController document];
    NSXMLDocument * svgXmlDocument = macSVGDocument.svgXmlDocument;
    NSXMLElement * rootElement = [svgXmlDocument rootElement];
    
    [self findAnimationElementsInElement:rootElement animationElementsArray:animationElementsArray];
    
    [self.timelineElementsArray removeAllObjects];
    
    [self addAbsoluteTimeElementsToTimeline:animationElementsArray];
    
    [self addEventElementsToTimeline:animationElementsArray];
    
    NSArray * sortedArray = [self.timelineElementsArray sortedArrayUsingFunction:timelineSort context:NULL];
    
    [self.timelineElementsArray setArray:sortedArray];

    [self reorderTimelineRows];
    
    [self setTimelineViewSize];

    [self.timelineLabelsTableViewDelegate reloadView];
   
    [self setNeedsDisplay:YES];
}

//==================================================================================
//	drawTimelineScale:
//==================================================================================

- (void)drawTimelineScale:(NSRect)dirtyRect
{
    // Drawing code here.
    NSRect frameRect = self.frame;
        
    NSMutableDictionary * textAttributes = [[NSMutableDictionary alloc] init];
    [textAttributes setObject:self.grayColor forKey:NSForegroundColorAttributeName];
    
    if (self.pixelsPerSecond == 0.0f)
    {
        self.pixelsPerSecond = 100.0f;
    }
    
    float tenthInterval = self.pixelsPerSecond / 10.0f;
    
    int tickCounter = 0;
    
    for (int x = 0; x < frameRect.size.width; x += tenthInterval)
    {
        if (x > 0)
        {
            float tickWidth = 1.0f;
            float markerOffset = 0.5f;

            [self.lightGrayColor set];
            
            if ((tickCounter % 5) == 0)
            {
            }
            
            if ((tickCounter % 10) == 0)
            {
                tickWidth = 2.0f;
                markerOffset = 0.0f;
                [self.grayColor set];
            }
            
            // Set the line width for a single NSBezierPath object.
            NSBezierPath* thePath = [NSBezierPath bezierPath];
            
            float topY = frameRect.size.height;
            
            [thePath moveToPoint:NSMakePoint(x + markerOffset, topY)];
            [thePath lineToPoint:NSMakePoint(x + markerOffset, 0)];

            [thePath setLineWidth:tickWidth];

            [thePath stroke];
        }

        tickCounter++;
    }
    
    [self setPlayHeadPosition:self.timeValue];
}

//==================================================================================
//	drawTimelineElements:
//==================================================================================

- (void)drawTimelineElements:(NSRect)dirtyRect
{
    //NSRect frameRect = self.frame;

    for (AnimationTimelineElement * animationTimelineElement in self.timelineElementsArray)
    {
        NSMutableArray * animationTimespanArray = 
                animationTimelineElement.animationTimespanArray;
        
        for (AnimationTimespan * animationTimespan in animationTimespanArray)
        {
            int colorIndex = animationTimespan.colorIndex;

            NSRect timelineRect = animationTimespan.timelineRect;
    
            NSRect offsetTimelineRect = timelineRect;
            offsetTimelineRect.origin.y += 1;
                        
            NSBezierPath * rectPath = [NSBezierPath bezierPathWithRect:offsetTimelineRect];
                        
            switch (colorIndex) 
            {
                case 0:
                    [self.lightGreenColor set];
                    break;
                case 1:
                    [self.lightYellowColor set];
                    break;
                case 2:
                    [self.cyanColor set];
                    break;
                default:
                    [self.redColor set];
                    break;
            }
            
            [rectPath fill];
            
            [self.blackColor set];
            [rectPath stroke];

            NSPoint descriptionPoint = NSMakePoint(offsetTimelineRect.origin.x + 5, offsetTimelineRect.origin.y + 5);
            
            NSString * description = animationTimelineElement.elementDescription;
            
            [description drawAtPoint:descriptionPoint withAttributes:0];

        }
    }
}

//==================================================================================
//	isFlipped
//==================================================================================

- (BOOL) isFlipped
{
    return YES;
}

//==================================================================================
//	drawRect:
//==================================================================================

- (void)drawRect:(NSRect)dirtyRect
{
    [self.whiteColor set];
    [NSBezierPath fillRect:dirtyRect];
    
    [self drawTimelineScale:dirtyRect];
    
    [self drawTimelineElements:dirtyRect];
}

@end