-- Tally — seed data, generated verbatim from the prototype's QUICK_FOODS_SEED array.
-- Run this once after schema.sql. Safe to re-run against an empty schema; NOT idempotent
-- against a modified catalog (it will error on duplicate ids) — truncate first if reseeding.

-- Insert foods first with default_variant_id left null, then variants, then backfill —
-- avoids needing a circular FK between foods and food_variants.

insert into foods (id, name, emoji, is_custom, unit, pluralize, step, btn_step, min_qty, max_qty, default_qty, grams_per_unit, native_is_oz, pick_required, item_mode, items_per_serving, item_name, protein_g, carbs_g, fat_g, macro_tag, meal_tags) values
  ('egg', 'Egg', '🥚', false, 'egg', true, 1, 1, 1, 6, 1, 50, false, false, false, null, null, 6, 0.6, 5, 'p', '{breakfast}'),
  ('oats', 'Oats', '🥣', false, 'serving (½ cup)', false, 1, 1, 1, 3, 1, 40, false, false, false, null, null, 5, 27, 3, 'c', '{breakfast}'),
  ('yogurt', 'Greek Yogurt', '🥛', false, 'cup', false, 0.25, 0.25, 0.25, 2, 1, 245, false, false, false, null, null, 23, 9, 0.5, 'p', '{breakfast,snack}'),
  ('avocado', 'Avocado', '🥑', false, 'half', false, 1, 1, 1, 4, 1, 65, false, false, false, null, null, 1.5, 6, 10, 'f', '{breakfast,mains}'),
  ('bacon', 'Bacon', '🥓', false, 'slice', true, 1, 1, 1, 8, 1, 8, false, false, false, null, null, 3, 0, 3, 'p', '{breakfast}'),
  ('syrup', 'Maple Syrup', '🍁', false, 'tbsp', false, 0.5, 0.5, 0.5, 4, 1, 20, false, false, false, null, null, 0, 13, 0, 'c', '{breakfast}'),
  ('honey', 'Honey', '🍯', false, 'tbsp', false, 0.5, 0.5, 0.5, 4, 1, 21, false, false, false, null, null, 0, 16, 0, 'c', '{breakfast}'),
  ('lime', 'Lime/Lemon', '🍋', false, 'half', false, 1, 1, 1, 4, 1, 34, false, false, false, null, null, 0.2, 3.5, 0.1, 'other', '{breakfast,mains,snack}'),
  ('pancake', 'Pancake', '🥞', false, 'pancake', true, 1, 1, 1, 4, 1, 40, false, false, false, null, null, 2.5, 14, 2.5, 'c', '{breakfast}'),
  ('waffle', 'Waffle', '🧇', false, 'waffle', true, 1, 1, 1, 4, 1, 35, false, false, false, null, null, 3, 15, 3, 'c', '{breakfast}'),
  ('butter', 'Butter', '🧈', false, 'tbsp', false, 0.5, 0.5, 0.5, 3, 1, 14, false, false, false, null, null, 0, 0, 11, 'f', '{breakfast}'),
  ('cottagecheese', 'Cottage Cheese', '🥣', false, 'cup', false, 0.25, 0.25, 0.25, 2, 1, 226, false, false, false, null, null, 25, 6, 5, 'p', '{breakfast,snack}'),
  ('tea', 'Tea', '🍵', false, 'cup', false, 0.5, 0.5, 0.5, 4, 1, 240, false, false, false, null, null, 0, 0, 0, 'other', '{breakfast}'),
  ('milk', 'Milk', '🥛', false, 'cup', false, 0.25, 0.25, 0.25, 3, 1, 244, false, false, false, null, null, 8, 12, 5, 'other', '{breakfast}'),
  ('oj', 'Orange Juice', '🧃', false, 'cup', false, 0.25, 0.25, 0.25, 2, 1, 248, false, false, false, null, null, 1.7, 26, 0.5, 'other', '{breakfast}'),
  ('coffee', 'Black Coffee', '☕', false, 'cup', false, 0.5, 0.5, 0.5, 4, 1, 240, false, false, false, null, null, 0, 0, 0, 'other', '{breakfast}'),
  ('soda', 'Soda', '🥤', false, 'can', true, 1, 1, 1, 3, 1, 355, false, false, false, null, null, 0, 39, 0, 'other', '{snack}'),
  ('chicken', 'Chicken', '🍗', false, 'oz', false, 1, 1, 1, 12, 4, 28.35, true, true, false, null, null, 9, 0, 1, 'p', '{mains}'),
  ('beef', 'Ground Beef', '🥩', false, 'oz', false, 1, 1, 1, 12, 4, 28.35, true, true, false, null, null, 5.25, 0, 3.5, 'p', '{mains}'),
  ('steak', 'Steak', '🍖', false, 'oz', false, 1, 1, 1, 12, 4, 28.35, true, true, false, null, null, 7, 0, 3.5, 'p', '{mains}'),
  ('fish', 'Fish', '🐟', false, 'oz', false, 1, 1, 1, 10, 4, 28.35, true, true, false, null, null, 6.25, 0, 2.25, 'p', '{mains}'),
  ('deli', 'Deli Meat', '🥪', false, 'oz', false, 1, 1, 1, 8, 2, 28.35, true, true, false, null, null, 5.5, 0.3, 0.3, 'p', '{mains}'),
  ('bread', 'Bread', '🍞', false, 'slice', true, 1, 1, 1, 4, 1, 28, false, true, false, null, null, 4, 14, 1, 'c', '{breakfast,mains}'),
  ('rice', 'Rice', '🍚', false, 'cup', false, 0.25, 0.25, 0.25, 3, 1, 158, false, true, false, null, null, 4.3, 45, 0.4, 'c', '{mains}'),
  ('sweetpotato', 'Sweet Potato', '🍠', false, 'potato', true, 1, 1, 1, 4, 1, 130, false, false, false, null, null, 2, 27, 0.2, 'c', '{mains}'),
  ('vegetables', 'Vegetables', '🥕', false, 'cup', false, 0.5, 0.5, 0.5, 6, 1, 91, false, true, false, null, null, 3, 6, 0.3, 'other', '{mains}'),
  ('blackbeans', 'Black Beans', '🫘', false, 'cup', false, 0.25, 0.25, 0.25, 2, 1, 172, false, false, false, null, null, 15, 41, 1, 'c', '{mains}'),
  ('chickpeas', 'Chickpeas', '🧆', false, 'cup', false, 0.25, 0.25, 0.25, 2, 1, 164, false, false, false, null, null, 14.5, 45, 4, 'c', '{mains}'),
  ('lentils', 'Lentils', '🍲', false, 'cup', false, 0.25, 0.25, 0.25, 2, 1, 198, false, false, false, null, null, 18, 40, 0.8, 'c', '{mains}'),
  ('tofu', 'Tofu', '🥡', false, 'cup', false, 0.25, 0.25, 0.25, 2, 1, 252, false, false, false, null, null, 20, 5, 11, 'p', '{mains}'),
  ('hummus', 'Hummus', '🫙', false, 'tbsp', false, 1, 1, 1, 8, 1, 15, false, false, false, null, null, 1.2, 3, 1.3, 'f', '{snack,mains}'),
  ('oliveoil', 'Olive Oil', '🫒', false, 'tbsp', false, 0.5, 0.5, 0.5, 3, 1, 14, false, false, false, null, null, 0, 0, 14, 'f', '{mains}'),
  ('quinoa', 'Quinoa', '🌾', false, 'cup', false, 0.25, 0.25, 0.25, 3, 1, 185, false, false, false, null, null, 8, 39, 4, 'c', '{mains}'),
  ('pasta', 'Pasta', '🍝', false, 'cup', false, 0.5, 0.5, 0.5, 3, 1, 140, false, false, false, null, null, 7, 37, 1, 'c', '{mains}'),
  ('cheese', 'Cheese', '🧀', false, 'oz', false, 0.5, 0.5, 0.5, 6, 1, 28.35, true, true, false, null, null, 7, 0, 9, 'f', '{breakfast,mains,snack}'),
  ('stringcheese', 'String Cheese', '🧀', false, 'stick', true, 1, 1, 1, 4, 1, 28, false, false, false, null, null, 7, 1, 6, 'f', '{snack}'),
  ('almonds', 'Almonds', '🌰', false, 'oz', false, 0.5, 0.5, 0.5, 4, 1, 28.35, true, false, false, null, null, 6, 6, 13, 'f', '{snack}'),
  ('pb', 'Peanut Butter', '🥜', false, 'tbsp', false, 0.5, 0.5, 0.5, 4, 1, 16, false, false, false, null, null, 4, 3, 8, 'f', '{breakfast,snack}'),
  ('fruit', 'Fruit', '🍎', false, 'apple', true, 1, 1, 1, 4, 1, 182, false, true, false, null, null, 0.5, 25, 0.3, 'c', '{breakfast,snack}'),
  ('popcorn', 'Popcorn', '🍿', false, 'cup', false, 0.5, 0.5, 0.5, 6, 1, 8, false, true, false, null, null, 1, 6, 0.3, 'c', '{snack}'),
  ('darkchoc', 'Dark Chocolate', '🍫', false, 'oz', false, 0.5, 0.5, 0.5, 4, 1, 28.35, true, false, false, null, null, 2, 13, 9, 'f', '{snack}'),
  ('chips', 'Chips', '🍟', false, 'oz', false, 0.5, 0.5, 0.5, 4, 1, 28.35, true, true, false, null, null, 2, 15, 10, 'f', '{snack}'),
  ('pretzels', 'Pretzels', '🥨', false, 'oz', false, 0.5, 0.5, 0.5, 4, 1, 28.35, false, true, false, null, null, 3.5, 22, 1, 'c', '{snack}'),
  ('candybar', 'Candy Bar', '🍫', false, 'bar', true, 1, 1, 1, 3, 1, 45, false, false, false, null, null, 2, 28, 11, 'c', '{snack}'),
  ('oreos', 'Oreos', '🍪', false, null, false, null, null, null, null, null, null, false, false, true, 3, 'cookie', 1, 25, 7, 'c', '{snack}'),
  ('chipsahoy', 'Chips Ahoy', '🍪', false, null, false, null, null, null, null, null, null, false, false, true, 3, 'cookie', 1.5, 22, 8, 'c', '{snack}'),
  ('icecream', 'Ice Cream', '🍨', false, 'serving (½ cup)', false, 0.5, 0.5, 0.5, 4, 1, 66, false, false, false, null, null, 2, 16, 7, 'f', '{snack}'),
  ('shake', 'Protein Shake', '🥤', false, 'scoop', true, 1, 1, 1, 4, 1, 30, false, false, false, null, null, 24, 3, 2, 'p', '{breakfast,snack}'),
  ('celery', 'Celery', '🥒', false, 'stalk', true, 1, 1, 1, 6, 1, 40, false, false, false, null, null, 0.3, 1.5, 0, 'other', '{mains,snack}');

insert into food_variants (id, food_id, name, protein_g, carbs_g, fat_g, unit, pluralize, step, btn_step, min_qty, max_qty, default_qty, grams_per_unit, sort_order) values
  ('chicken-tenderloin', 'chicken', 'Chicken Tenderloin', 9.2, 0, 0.6, null, null, null, null, null, null, null, null, 0),
  ('chicken-breast', 'chicken', 'Chicken Breast', 9, 0, 1, null, null, null, null, null, null, null, null, 1),
  ('chicken-thigh', 'chicken', 'Chicken Thigh', 7.3, 0, 3.1, null, null, null, null, null, null, null, null, 2),
  ('beef-9307', 'beef', '93/7 Ground Beef', 5.5, 0, 2.5, null, null, null, null, null, null, null, null, 0),
  ('beef-9010', 'beef', '90/10 Ground Beef', 5.25, 0, 3.5, null, null, null, null, null, null, null, null, 1),
  ('beef-8515', 'beef', '85/15 Ground Beef', 5, 0, 4.5, null, null, null, null, null, null, null, null, 2),
  ('steak-tritip', 'steak', 'Tri-Tip Steak', 7.5, 0, 1.5, null, null, null, null, null, null, null, null, 0),
  ('steak-sirloin', 'steak', 'Top Sirloin Steak', 7.5, 0, 2, null, null, null, null, null, null, null, null, 1),
  ('steak-ribeye', 'steak', 'Ribeye Steak', 6.5, 0, 5.5, null, null, null, null, null, null, null, null, 2),
  ('steak-ny', 'steak', 'New York Strip', 7, 0, 3.5, null, null, null, null, null, null, null, null, 3),
  ('fish-salmon', 'fish', 'Salmon', 6.25, 0, 2.25, null, null, null, null, null, null, null, null, 0),
  ('fish-cod', 'fish', 'Cod', 6.3, 0, 0.2, null, null, null, null, null, null, null, null, 1),
  ('fish-tilapia', 'fish', 'Tilapia', 6.4, 0, 0.5, null, null, null, null, null, null, null, null, 2),
  ('fish-shrimp', 'fish', 'Shrimp', 6, 0, 0.3, null, null, null, null, null, null, null, null, 3),
  ('fish-tuna', 'fish', 'Tuna', 6.5, 0, 0.2, null, null, null, null, null, null, null, null, 4),
  ('deli-turkey', 'deli', 'Turkey Breast (Deli)', 5.5, 0.3, 0.3, null, null, null, null, null, null, null, null, 0),
  ('deli-ham', 'deli', 'Ham', 5, 0.5, 1.5, null, null, null, null, null, null, null, null, 1),
  ('deli-roastbeef', 'deli', 'Roast Beef', 6, 0.3, 1.2, null, null, null, null, null, null, null, null, 2),
  ('bread-wheat', 'bread', 'Whole Wheat Bread', 4, 14, 1, 'slice', null, null, null, null, null, null, 28, 0),
  ('bread-bagel', 'bread', 'Bagel', 9, 47, 1.5, 'bagel', null, null, null, null, null, null, 90, 1),
  ('bread-muffin', 'bread', 'English Muffin', 5, 26, 1, 'muffin', null, null, null, null, null, null, 57, 2),
  ('rice-white', 'rice', 'White Rice', 4.3, 45, 0.4, null, null, null, null, null, null, null, null, 0),
  ('rice-brown', 'rice', 'Brown Rice', 5, 45, 1.8, null, null, null, null, null, null, null, null, 1),
  ('rice-wild', 'rice', 'Wild Rice', 6.5, 35, 0.5, null, null, null, null, null, null, null, null, 2),
  ('veg-broccoli', 'vegetables', 'Broccoli', 3, 6, 0.3, null, null, null, null, null, null, null, 91, 0),
  ('veg-spinach', 'vegetables', 'Spinach', 1, 1, 0, null, null, null, null, null, null, null, 30, 1),
  ('veg-pepper', 'vegetables', 'Bell Pepper', 1, 6, 0.2, null, null, null, null, null, null, null, 149, 2),
  ('veg-carrots', 'vegetables', 'Carrots', 1, 12, 0.3, null, null, null, null, null, null, null, 128, 3),
  ('veg-tomato', 'vegetables', 'Tomato', 1.5, 7, 0.4, null, null, null, null, null, null, null, 180, 4),
  ('veg-cucumber', 'vegetables', 'Cucumber', 0.8, 4, 0.1, null, null, null, null, null, null, null, 119, 5),
  ('veg-corn', 'vegetables', 'Corn', 5, 34, 2, null, null, null, null, null, null, null, 154, 6),
  ('veg-asparagus', 'vegetables', 'Asparagus', 3, 4, 0.2, null, null, null, null, null, null, null, 134, 7),
  ('veg-greenbeans', 'vegetables', 'Green Beans', 2, 10, 0.2, null, null, null, null, null, null, null, 100, 8),
  ('veg-zucchini', 'vegetables', 'Zucchini', 1.5, 3, 0.4, null, null, null, null, null, null, null, 124, 9),
  ('veg-brussels', 'vegetables', 'Brussels Sprouts', 3, 6, 0.3, null, null, null, null, null, null, null, 88, 10),
  ('veg-kale', 'vegetables', 'Kale', 2, 5, 0.5, null, null, null, null, null, null, null, 67, 11),
  ('cheese-cheddar', 'cheese', 'Cheddar', 7, 0, 9, null, null, null, null, null, null, null, null, 0),
  ('cheese-mozzarella', 'cheese', 'Mozzarella', 6.5, 0.6, 5, null, null, null, null, null, null, null, null, 1),
  ('cheese-feta', 'cheese', 'Feta', 4, 1.2, 6, null, null, null, null, null, null, null, null, 2),
  ('cheese-swiss', 'cheese', 'Swiss', 7.6, 1.5, 7.8, null, null, null, null, null, null, null, null, 3),
  ('cheese-parmesan', 'cheese', 'Parmesan', 10, 0.9, 7.3, null, null, null, null, null, null, null, null, 4),
  ('cheese-creamcheese', 'cheese', 'Cream Cheese', 1.7, 1.4, 9.8, null, null, null, null, null, null, null, null, 5),
  ('fruit-apple', 'fruit', 'Apple', 0.5, 25, 0.3, 'apple', true, null, null, null, null, null, 182, 0),
  ('fruit-banana', 'fruit', 'Banana', 1.3, 24, 0.4, 'banana', true, null, null, null, null, null, 118, 1),
  ('fruit-orange', 'fruit', 'Orange', 1.2, 15.4, 0.2, 'orange', true, null, null, null, null, null, 131, 2),
  ('fruit-blueberries', 'fruit', 'Blueberries', 1, 21, 0.5, 'cup', false, null, null, null, null, null, 148, 3),
  ('fruit-grapes', 'fruit', 'Grapes', 0.6, 27, 0.2, 'cup', false, null, null, null, null, null, 151, 4),
  ('fruit-strawberries', 'fruit', 'Strawberries', 1, 11.7, 0.5, 'cup', false, null, null, null, null, null, 152, 5),
  ('popcorn-home', 'popcorn', 'Homemade Popcorn', 1, 6, 0.3, null, null, null, null, null, null, null, null, 0),
  ('popcorn-theater', 'popcorn', 'Movie Theatre Popcorn', 1.5, 6, 4, null, null, null, null, null, null, null, null, 1),
  ('popcorn-microwave', 'popcorn', 'Microwave Popcorn', 1.5, 6, 2.2, null, null, null, null, null, null, null, null, 2),
  ('chips-potato', 'chips', 'Potato Chips', 2, 15, 10, null, null, null, null, null, null, null, null, 0),
  ('chips-tortilla', 'chips', 'Tortilla Chips', 2, 18, 7.5, null, null, null, null, null, null, null, null, 1),
  ('chips-corn', 'chips', 'Corn Chips', 2, 16, 9.5, null, null, null, null, null, null, null, null, 2),
  ('pretzel-hard', 'pretzels', 'Hard Pretzels', 3.5, 22, 1, null, null, null, null, null, null, null, null, 0),
  ('pretzel-soft', 'pretzels', 'Soft Pretzel', 9, 72, 2, 'pretzel', true, 1, 1, 1, 3, 1, 120, 1);

-- backfill each food's sticky default variant
update foods set default_variant_id = 'chicken-breast' where id = 'chicken';
update foods set default_variant_id = 'beef-9010' where id = 'beef';
update foods set default_variant_id = 'steak-ny' where id = 'steak';
update foods set default_variant_id = 'fish-salmon' where id = 'fish';
update foods set default_variant_id = 'deli-turkey' where id = 'deli';
update foods set default_variant_id = 'bread-wheat' where id = 'bread';
update foods set default_variant_id = 'rice-white' where id = 'rice';
update foods set default_variant_id = 'veg-broccoli' where id = 'vegetables';
update foods set default_variant_id = 'cheese-cheddar' where id = 'cheese';
update foods set default_variant_id = 'fruit-apple' where id = 'fruit';
update foods set default_variant_id = 'popcorn-home' where id = 'popcorn';
update foods set default_variant_id = 'chips-potato' where id = 'chips';
update foods set default_variant_id = 'pretzel-hard' where id = 'pretzels';
