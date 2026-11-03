# Unvarnished

A painting, five details, three statements each. Only one is true.

The app zooms into a part of a masterpiece and asks which statement about it is true. After each pick it marks every statement True or False and says why, so a wrong guess still teaches you something. Get all five rounds of a painting right and it's acquired for your collection, where you can look back at it and the five things you learned.

## The paintings

There are 100, from the 1290s to 1930: Old Masters, Impressionists, Japanese prints, a Chinese handscroll, a Roman-Egyptian mummy portrait, and modern work including Matisse, Kandinsky, Malevich, Klee and two Mondrians.

They're grouped into eight categories: Renaissance, Golden Age & Baroque, Rococo & Revolution, Romantics & Realists, Impressionism, After Impressionism, Modern, and Asia & Antiquity. On the home screen you pick a category (or All), and the next painting comes from it. Your collection is grouped the same way. The categories, and which painting belongs to each, are set in `tools/categories.py`.

Every image is in the public domain. They come from the Met and the Cleveland Museum of Art (both CC0) and from Wikimedia Commons, which hosts public-domain scans from the Rijksmuseum, the National Gallery, the Prado, the Art Institute of Chicago and others. Modern works are limited to pieces made before 1931 by artists who died before 1956, so they're out of copyright in both the US and Europe.

## Adding or editing paintings

The rounds are written by hand in `tools/content/*.txt`, one block per painting:

```
## id | Title | Artist | artist dates | date | medium | collection
desc: What the image shows, for VoiceOver.
@ x y zoom | Where label | Prompt | Hint
+ The true statement || Why it's true
- A false statement || Why it's false
- Another false statement || Why it's false
```

Each painting has five `@` rounds. `x` and `y` are where to zoom, as fractions of the image width and height (0 to 1), and `zoom` is how far (1 shows the whole painting; keep it at 3 or below so the detail stays sharp).

To add a painting:

1. Add its image source to `tools/manifest.py`.
2. Download the images. This needs Pillow:

   ```bash
   python tools/fetch_images.py <image_dir> <id>
   ```

3. Check the image and pick zoom points from a gridded contact sheet:

   ```bash
   python tools/contact_sheet.py <image_dir> <sheet_dir>
   ```

4. Write its rounds in a content file, add its id to a category in `tools/categories.py`, and write a summary of about 100 words in `tools/content/summaries/` (shown on the score screen and in Your Collection).
5. Build the app's JSON and copy the images in. This step also checks that every painting has five rounds with exactly one true statement each, and belongs to exactly one category:

   ```bash
   python tools/build_content.py <image_dir>
   ```

The Xcode project and source folder still use the working name, OneTrueThing. Rounds get harder as they go. Rounds 1 and 2 are warm-ups with clearly false answers. From round 3 the false statements are believable facts with one thing wrong, and by round 5 all three are the same kind of claim, differing only in a key name, date or number. The build also checks that, from round 3 on, the true statement isn't noticeably longer than the false ones.

To rewrite many rounds at once, `tools/apply_rewrites.py` swaps new statements into the content files (see the format at the top of the script).

`OneTrueThing/Paintings/milkmaid.json` was written by hand before the content files existed, and is edited directly.

Check every true statement against the museum's own catalogue before shipping.
