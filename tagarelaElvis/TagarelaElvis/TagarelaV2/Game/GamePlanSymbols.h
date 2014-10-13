//
//  Game_plan_symbols.h
//  Tagarela
//
//  Created by Elvis Merten Marques on 10/10/14.
//  Copyright (c) 2014 Alan Filipe Cardozo Fabeni. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GroupPlan;

@interface GamePlanSymbols : NSManagedObject

@property (nonatomic, retain) NSNumber * server_ID;
@property (nonatomic, retain) NSNumber * plan_ID;
@property (nonatomic, retain) NSNumber * background_symbol_id;
@property (nonatomic, retain) NSNumber * path_symbol_id;
@property (nonatomic, retain) NSNumber * predator_symbol_id;
@property (nonatomic, retain) NSNumber * prey_id;
@property (nonatomic, retain) GroupPlan *groupPlanFrom;

@end

@interface GamePlanSymbols (CoreDataGeneratedAccessors)
-(NSArray*) loadSymbolsFromPlanGame:(int) planId;
-(void) changeGamePlanSymbolsIds: (NSArray*) symbolsId ofGroupPlan: (int) groupPlanId;
@end