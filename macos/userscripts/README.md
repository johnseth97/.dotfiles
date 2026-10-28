# Ghost Pastel for Lichess

`lichess-ghost-pastel.user.css` uses the palette in
[`../.config/theme/colors.toml`](../.config/theme/colors.toml), with near-black
surfaces, periwinkle controls, pastel text accents, and pastel move overlays.
With **Background image** enabled, it preserves your selected image, image
opacity, and Lichess's native translucent panels. Solid Ghost Pastel surfaces
apply only when the background image is off.

It is plain CSS and runs only on `https://lichess.org/*`.

## Install in Safari Userscripts

1. Open the Userscripts extension's editor in Safari.
2. Choose **+ → New CSS**.
3. Replace the template with the **entire** `.user.css` file, including its
   `==UserStyle==` metadata comment, then save and enable it.
4. Allow the extension on `lichess.org` if needed, and reload Lichess.

Alternatively, copy the file into the save location configured in Userscripts.
You do not need to change the extension's save location to this directory.

The extension documents the [CSS editor and metadata format here](https://github.com/quoid/userscripts#ui-overview).
This file deliberately does not use Stylus-only `@-moz-document` wrappers.

## Adjust or remove

- Edit the `--gp-*` variables at the top to tune colors.
- Keep your existing appearance settings, including **Dark**, **Background
  image**, **50% image opacity**, and **8px roundness**. The stylesheet does not
  set the image URL or override either the image or board opacity controls.
- Board square colors, textures, coordinates, pieces, and board effects remain
  controlled by Lichess's own settings.
- Last-move and selection highlights, legal-move/capture indicators, and premove
  overlays use Ghost Pastel colors. Remove the final **MOVE OVERLAYS** section
  if you also want Lichess to control those colors.
- Disable this CSS entry and reload to restore Lichess's own appearance.

The style changes appearance only. It preserves layout, fonts, piece sets,
analysis arrows, evaluation bars, and Lichess's status/move-quality colors.
Its shared theme variables target Lichess's current interface; future markup or
theme-variable changes may need corresponding updates here.
