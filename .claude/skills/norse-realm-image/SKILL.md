---
name: norse-realm-image
description: Use when adding a mythology image to a Norse Architecture realm README — places the image after the opening quote, replaces the bland alt text with lore-appropriate copy, and appends @norsemythologyclips attribution.
---

# Norse Realm Image

## Overview

Inserts an image into a realm README in the canonical position (after the opening quote, before the body), swaps `alt="Image"` for lore-appropriate copy, and appends the standard attribution line.

## Steps

1. **Read the target README** — confirm the opening `>` quote block exists and locate the line immediately after it.
2. **Craft the alt text** — draw from the realm's mythological essence, not just its name. Formula: `{Realm} — {what it is/does in the lore, 1 clause}`. See the reference table below.
3. **Insert the block** between the closing quote line and the first body paragraph:

```markdown
<p align="center">
  <img src="{URL}" alt="{lore alt text}" title="{lore title}" />
</p>

*Image credit: [@norsemythologyclips](https://www.instagram.com/norsemythologyclips/) — go follow them.*
```

The **alt text** is the full lore description (see table). The **title** (tooltip) is a shorter punchy phrase — realm name + one defining trait. Keep them distinct.

4. Blank line before the `<p align="center">` block, blank line after the attribution, then the body continues.

**Why `<p align="center">` and not a plain `style="..."` attribute on `<img>`:** GitHub's markdown sanitizer strips `style` attributes off `<img>` tags, so inline centering (`style="display: block; margin: 0 auto;"`) silently renders left-aligned. `align` on a wrapping `<p>` survives sanitization and is the only centering approach confirmed to render on GitHub (verified live on Asgard, 2026-08-01). Markdown has no native image-centering syntax, so this HTML wrapper is required — don't fall back to plain `![alt](url "title")` for new realms.

## Alt Text & Title Reference

| Realm | Alt text (full description) | Title (tooltip) |
|---|---|---|
| Bifrost | `Bifrost — the shimmering rainbow bridge spanning the nine realms, the only passage between worlds` | `Bifrost — the rainbow bridge between the realms` |
| Glitnir | `Glitnir — the shining hall, its pillars of gold and roof of silver` | `Glitnir — the shining hall of the design court` |
| Heimdall | `Heimdall — the ever-vigilant watchman of the gods, keeper of the Bifrost, whose sight and hearing know no limit` | `Heimdall — the watchman who decides who crosses Bifrost` |
| Himinbjörg | `Himinbjörg — Heimdall's hall where heaven meets the bridge, standing watch at the edge of the nine realms` | `Himinbjörg — Heimdall's hall at the head of Bifrost` |
| Naglfar | `Naglfar — the ship of the dead, assembled from the nails of the slain, bound for Ragnarök` | `Naglfar — the ship built to deliver everything to where it's going` |
| Yggdrasil | `Yggdrasil — the immense world tree whose roots reach into the underworld and whose branches cradle the nine realms` | `Yggdrasil — the world tree whose branches and roots bind all nine realms together` |
| Svartalfheim | `Svartalfheim — the underground realm of the dvergar, where the fires of the forge never die and the finest weapons in the nine realms are hammered into being` | `Svartalfheim — home of the dvergar, master smiths of the nine realms` |
| Asgard | `Asgard — the golden fortress of the Æsir, where the gods hold council and the laws that govern all nine realms are declared` | `Asgard — the fortress where law is declared and the cosmos answers to it` |
| Ratatoskr | `Ratatoskr — the sly squirrel who races the length of Yggdrasil, carrying messages between the eagle at the crown and Níðhöggr gnawing at the roots` | `Ratatoskr — the original message broker` |
| Midgard | `Midgard — the realm of humankind, where the will of the gods descends from Asgard and takes concrete form in the world` | `Midgard — where the will of the gods takes physical form` |
| Urdarbrunnr | `Urdarbrunnr — the Well of Urd beneath Yggdrasil's roots, where the Norns weave fate and keep the record of all that has become` | `Urdarbrunnr — the record of all that has become` |
| Ginnungagap | `Ginnungagap — the primordial void before all creation, where the ice of Niflheim and the fire of Muspelheim met and breathed the nine realms into being` | `Ginnungagap — the void before creation, the source of all realms` |
| Mímisbrunnr | `Mímisbrunnr — the well of wisdom at Yggdrasil's roots, guarded by Mímir, where Odin traded an eye for a single drink of it` | `Mímisbrunnr — the well Odin paid an eye to drink from` |
| Mímir | `Mímir — beheaded in the Æsir-Vanir war, yet still carried and consulted by Odin for counsel` | `Mímir — the severed head Odin still consults for counsel` |
| Bragi | `Bragi — the skaldic god of poetry, master of eloquence, welcoming the honored dead into Valhalla with song` | `Bragi — the skald who sings of everything aboard the ship` |

For a realm not yet in the table: lean on its defining lore trait — what makes it mythologically distinct? Add the new entry to this table after use.

## Attribution Line

Always identical — do not paraphrase:

```markdown
*Image credit: [@norsemythologyclips](https://www.instagram.com/norsemythologyclips/) — go follow them.*
```
