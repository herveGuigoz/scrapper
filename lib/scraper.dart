import 'dart:convert';
import 'dart:io';
import 'package:puppeteer/puppeteer.dart';
import 'package:scraper/src/recipe.dart';

export 'src/files.dart';

const EMAIL = 'nellynambot@gmail.com';
const PASSWORD = '10QuaiJJ';

const HOME = 'https://www.cuisinez-pour-bebe.fr';
const INDEX = 'https://www.cuisinez-pour-bebe.fr/recette-bebe/';

const JSON_PATHS = 'generated/paths.json';
const JSON_RECIPES = 'generated/recipes.json';

/// Start and close the browser.
Future<void> run(Future<void> Function(Page page) cb) async {
  final browser = await puppeteer.launch();
  final page = await browser.newPage();
  await page.emulateMediaType(MediaType.screen);
  // await page.setViewport(DeviceViewport());
  await cb(page);
  await browser.close();
}

/// Log in, scrap and save to json all recipes paths.
Future<void> scrapAllPaths(Page page) async {
  await goTo(page, path: INDEX);
  await getAllPaths(page);
}

/// Log in and scrap recipes ids.
Future<void> scrapRecipesIds(Page page) async {
  final paths = await loadScrapedPaths();
  final recipes = <Recipe>[];

  for (final path in paths) {
    try {
      await goTo(page, path: path);
      final id = await getRecipeId(page);
      final recipe = Recipe(id: id, path: path);
      recipes.add(recipe);
      print(recipe);
    } catch (e) {
      continue;
    }
  }

  print(recipes.length);

  await saveRecipesToJson(recipes);
}

/// Save recipes to pdf
Future<void> recipesToPDF(Page page) async {
  final recipes = await loadScrapedRecipes();
  for (final recipe in recipes) {
    await goTo(
      page,
      path: 'https://www.cuisinez-pour-bebe.fr/wprm_print/${recipe.id}',
    );
    await saveToPDF(page, recipe.name);
  }
}

/// Return List of recipes path saved in json file
Future<List<String>> loadScrapedPaths() async {
  final file = await File(JSON_PATHS).readAsString();
  final json = jsonDecode(file) as Map<String, dynamic>;

  return List<String>.from(json['paths'] as List<dynamic>);
}

Future<List<Recipe>> loadScrapedRecipes() async {
  final file = await File(JSON_RECIPES).readAsString();
  final json = jsonDecode(file) as List<dynamic>;

  return json
      .map((dynamic e) => Recipe.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// Navigate to new page and wait for page to be fully loaded
Future<void> goTo(Page page, {String path}) async {
  await page.goto(path, wait: Until.networkIdle);
}

/// Take a screenshot of the page
Future<void> takeScreenshot(
  Page page, {
  String selector,
  String name = 'screenshot',
}) async {
  if (selector == null) {
    final screenshot = await page.screenshot();
    await File('generated/images/$name.png').writeAsBytes(screenshot);
  } else {
    final el = await page.$(selector);
    final screenshot = await el.screenshot();
    await File('generated/images/$name.png').writeAsBytes(screenshot);
  }
}

/// Return stats value from 'ais-Stats-text' span value on main screen
Future<int> getCount(Page page) async {
  final stats = await page.$eval('.ais-Stats-text', 'el => el.innerText');
  return int.parse((stats as String).split(' ').first);
}

/// Count number of recipes currently visible
Future<int> countNumberOfVisibleRecipies(Page page) async {
  final count = await page.$$eval('.ais-Hits-item', 'el => el.length');

  return count;
}

/// Return List of paths for all recipes on the screen
Future<List<String>> getPaths(Page page) async {
  return List<String>.from(await page.$$eval(
    '.ais-Hits-item > a',
    'el => el.map((x) => x.href)',
  ));
}

/// Login
Future<void> login(Page page) async {
  await goTo(page, path: HOME);
  final idle = await page.$('#top-menu li a');
  await idle.click();
  await page.waitForNavigation();
  await page.type('#iump_login_username', EMAIL);
  await page.type('#iump_login_password', PASSWORD);
  await page.click('input[type=submit]');
}

/// Find recipe id under .wprm-recipe-print-inline-button[data-recipe-id] attribute
Future<String> getRecipeId(Page page) async {
  final id = await page.$eval(
    '.wprm-recipe-print-inline-button',
    r"(el) => el.getAttribute('data-recipe-id')",
  );

  return id as String;
}

/// Generate a PDF from a page
Future<void> saveToPDF(Page page, String fileName) async {
  await page.pdf(
    format: PaperFormat.a4,
    printBackground: true,
    output: File('generated/pdf/$fileName.pdf').openWrite(),
  );
}

/// Save array of recipe paths to json file.
Future<void> savePathsToJson(Page page) async {
  final paths = await getPaths(page);
  final json = jsonEncode({'paths': paths});
  await File(JSON_PATHS).writeAsString(json);
}

/// Save array of Recipe to json file.
Future<void> saveRecipesToJson(List<Recipe> recipes) async {
  final json = jsonEncode(recipes.map((recipe) => recipe.toJson()).toList());
  await File(JSON_RECIPES).writeAsString(json);
}

/// Scroll down until no more item has been loaded
/// and save recipe paths to json file.
Future<void> getAllPaths(Page page) async {
  var hasMore = true;
  var count = await countNumberOfVisibleRecipies(page);
  if (count == 0) return;
  while (hasMore) {
    // Scroll down.
    await page.$eval(
      '.ais-Hits-item:last-child',
      '(el) => el.scrollIntoView()',
    );
    await Future.delayed(Duration(seconds: 2));
    final _count = await countNumberOfVisibleRecipies(page);
    if (_count == count) {
      hasMore = false;
    } else {
      count = _count;
    }
  }
  print(count);
  await savePathsToJson(page);
}
