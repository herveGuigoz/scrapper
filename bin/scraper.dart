import 'package:scraper/scraper.dart';

void main() async {
  final start = DateTime.now();
  await run((page) async {
    await login(page);
    await scrapAllPaths(page);
    await scrapRecipesIds(page);
    await recipesToPDF(page);
  });
  final end = DateTime.now();
  print('DONE IN ${end.difference(start).inSeconds} SECONDS');
}
