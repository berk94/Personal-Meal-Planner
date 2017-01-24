:-include('plannerData.pl').
%CMPE_260_PROJECT_1
%PERSONAL MEAL PLANNER
%%Author: Kemal Berk Kocabagli

%%%%EXTRA FUNCTIONS %%%%%%%

%%%%%%%%% Concatanates two lists %%%%%%%%%%%%%%%
concatList([],L,L).
concatList([H|L1],L2,[H|Flist]):- concatList(L1,L2,Flist).

%%%%%%%%% Removes the duplicates in the given list %%%%%%%%%%%%%%%
remDuplicates([],[]):-!.
remDuplicates([H|T],Flist):-
member(H,T),
remDuplicates(T,Flist).

remDuplicates([H|T],[H|X]):-
not(member(H,T)),
remDuplicates(T,X).

%%%%%%%%% The two functions collectively reverse a given list %%%%%%%%%%%%%%%
tempListforRev([],Temp,Temp).
tempListforRev([H|T],Temp,R):- tempListforRev(T,[H|Temp],R).

reverseList(L,R):-tempListforRev(L,[],R).

%%%%%%%%% Returns a list of every meal in the knowledge base %%%%%%%%%%%%%%%
allMeals(MealList):-
findall(X,meal(X,_,_,_,_),MealList).

%%%%%%%%% The two functions collectively find every meal containing the ingredients in the given IngredientList %%%%%%%%%%%%%%%
findIngredient(IngredientList, X):-
meal(X, IList, _, _, _),
member(Y,IList),
member(Y, IngredientList).

findallIngredients(IngredientList,InitialList, MealList):-
findall(X,(member(X,InitialList),findIngredient(IngredientList,X)),MealList).



%%%%%%%%%%%%%%%%%% ALLERGY %%%%%%%%%%%%%%%%%%%
% Finds the ingredients which the customer is allergic to given an AllergyList
findAllergyFood(AllergyList, FinalList):-
findall(X,(member(Allergic, AllergyList),foodGroup(Allergic, FoodList),member(X, FoodList)),FinalList).

% Finds all the meals that the customer is allergic to
findAllergyMeals(AllergyList, InitialList, Flist):-
findAllergyFood(AllergyList, DFoods),
findallIngredients(DFoods, InitialList, M_to_be_removed),
findall(X, (member(X,InitialList), member(X,M_to_be_removed)), Flist1),
remDuplicates(Flist1, Flist),
!.


%%%%%%%%%%%%%%%%%% LIKES %%%%%%%%%%%%%%%%%%%
% Finds the meals the customer likes based on one ingredient - used to prioritize the likes
findLikeMealForOneIng(Ingredient, InitialList, MealList):-

findall(M, (meal(M,_,_,_,_),findallIngredients([Ingredient], InitialList, L), member(M,L)) ,MealList1),
remDuplicates(MealList1, MealList),
!.

% Finds all of the meals the customer likes based on the Likes list, which contains ingredients
findLikeMeals(Likes, InitialList, AllFavMeals):-
findall(X, (member(Y,Likes),findLikeMealForOneIng(Y,InitialList,L1),member(X,L1)),AllFavMeals1),
reverseList(AllFavMeals1,AllFavMealsRev),
remDuplicates(AllFavMealsRev, AllFavMeals2),
reverseList(AllFavMeals2,AllFavMeals),
!.

%%%%%%%%%%%%%%%%%% DISLIKES %%%%%%%%%%%%%%%%%%%
% Finds the meals that the customer dislikes
findDislikeMeals(Dislikes, InitialList, Dontlike):-
findLikeMeals(Dislikes, InitialList, Dontlike1),
remDuplicates(Dontlike1, Dontlike),
!.

%%%%%%%%%%%%%%%%%% CANNOT EAT  %%%%%%%%%%%%%%%%%%%
% Finds the ingredients the customer cannot eat because of his eating type
findCannotEatFoodList(CannotEatFoodGroupList, InitialList, CannotEat):-
findall(X, (member(Y,CannotEatFoodGroupList), foodGroup(Y,CannotEatFoodList), findallIngredients(CannotEatFoodList, InitialList,CannotEat), member(X,CannotEat)), CannotEat).

% Finds the meals the customer cannot eat because of one of his eating types
findOneNotEatingTypeMeals(EatingType, InitialList, MealList):-
cannotEatGroup(EatingType, CannotEatFoodGroupList, CalorieLimit),
findCannotEatFoodList(CannotEatFoodGroupList, InitialList, CannotEat),
findall(M1, (member(M1,InitialList), member(M1,CannotEat)),L1),
findall(M2, (member(M2,InitialList), meal(M2,_,Calorie,_,_), dif(0,CalorieLimit),Calorie>CalorieLimit), L2),
findall(M, (member(M,L1);member(M,L2)), MealList1),
remDuplicates(MealList1, MealList),
!.

% Finds the meals the customer cannot eat because of all of his eating types
findNotEatingTypeMeals(EatingTypeList, InitialList, MealList):-
findall(M,(meal(M,_,_,_,_),member(X,EatingTypeList),findOneNotEatingTypeMeals(X, InitialList, L), member(M,InitialList),member(M,L)),MealList1),
remDuplicates(MealList1, MealList),
!.

%%%%%%%%%%%%%%%%%% TIME %%%%%%%%%%%%%%%%%%%
% Finds the meals the customer has enough time to eat
findMealsForTime(TimeInHand, InitialList, MealList):-
findall(X, (member(X,InitialList), meal(X,_,_,PrepTime,_),PrepTime=<TimeInHand), MealList).


%%%%%%%%%%%%%%%%%% MONEY %%%%%%%%%%%%%%%%%%%
% Finds the meals the customer has enough money to buy
findMealsForMoney(MoneyInHand, InitialList, MealList):-
findall(X, (member(X,InitialList),meal(X,_,_,_,Price),Price=<MoneyInHand), MealList).

%%%%%%%%%%%%%%%%%% ORDER LIKES %%%%%%%%%%%%%%%%%%%
% Puts the meals the customer likes in the beginning of the MealList
orderLikedList(LikeMeals, InitialList, MealList):-
findall(X, (member(X,LikeMeals),member(X,InitialList)),L1),
findall(Y, (member(Y,InitialList), not(member(Y,L1))),L2),
concatList(L1,L2,MealList1),
remDuplicates(MealList1, MealList),
!.

%%%%%%%%%%%%%%%%%% PERSONAL LIST %%%%%%%%%%%%%%%%%%%
% Determines the personal list of the customer with the name CustomerName

listPersonalList(CustomerName, PersonalList):-
customer(CustomerName, AllergyList, EatingType, Dislikes, Likes, TimeInHand, MoneyInHand),
allMeals(MealList),
findMealsForMoney(MoneyInHand, MealList, L),
findall(X,(member(X,MealList),member(X,L)),MealList1),
findMealsForTime(TimeInHand, MealList1, L1),
findall(X,(member(X,MealList1),member(X,L1)),MealList2),
findDislikeMeals(Dislikes, MealList2, L2),
findall(X,(member(X,MealList2),not(member(X,L2))),MealList3),
findAllergyMeals(AllergyList, MealList3, L3),
findall(X,(member(X,MealList3),not(member(X,L3))),MealList4),
findNotEatingTypeMeals(EatingType, MealList4, L4),
findall(X,(member(X,MealList4),not(member(X,L4))),MealList5),
findLikeMeals(Likes,MealList5,LikeMeals),
orderLikedList(LikeMeals,MealList5, PersonalList).

