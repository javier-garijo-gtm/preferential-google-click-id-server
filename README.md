# Preferential Google Ads Click ID - Fixed Analytics™

A **server-side Google Tag Manager (sGTM) variable template** for businesses that store multiple Google Ads click IDs in a database. Instead of deciding manually which ID to send with a conversion, it accepts up to six click ID sources, **automatically selects the preferred available ID**, and tells you which source supplied it. All six values remain available for other uses.

**Developed by Javier Garijo — Fixed Analytics™**

## Setup

1. In **Server GTM → Templates → Variable Templates**, import `template.tpl`.
2. Create a variable using this template, e.g. `{{Preferred Google Ads Click ID}}`.
3. In **Click IDs from database**, add a row for each stored ID: select **Click ID type** (such as `FPGCLAW` or `_gcl_aw`), then choose the **GTM variable containing that ID**. These variables can come from your existing database lookup or Object Property Extractor.
4. Supply the **click ID itself**, not the encoded cookie value (e.g. `ABC123`, not `2.1.kABC123$i1234`). You can leave unavailable IDs empty.

The table works on **all events** when another tag or variable references it. No event-name mapping or priority setup is required; **row order doesn't matter**.

## Priority

`FPGCLAW → _gcl_aw → FPGCLAG → _gcl_ag → FPGCLGB → _gcl_gb`

GCLID beats GBRAID, which beats WBRAID. Within each identifier type, the first-party (`FPGCL*`) value takes priority over the JavaScript (`_gcl_*`) value. This is a **fallback preference**, not a newest-click attribution calculation.

## Output object

For example, if your database provides FP GCLID and JS GBRAID:

```json
{
  "fp_gclid": "ABC123",
  "fp_gbraid": null,
  "fp_wbraid": null,
  "gclid": null,
  "gbraid": "DEF456",
  "wbraid": null,
  "preferential_click_id": "ABC123",
  "preferential_click_id_type": "FPGCLAW"
}
```

Create an **Object Property Extractor** variable with **Source Object** = `{{Preferred Google Ads Click ID}}` and **Property Name** = `preferential_click_id`. It returns `ABC123`, not the entire object. Use another extractor with `preferential_click_id_type` to identify the winning source (`FPGCLAW` here).

## Using it with Google Ads conversions

When configuring your conversion tag, send the chosen ID in the **correct Google Ads parameter** according to `preferential_click_id_type`:

| Winning source cookie | Google Ads parameter |
| --- | --- |
| `FPGCLAW`, `_gcl_aw` | `gclid` |
| `FPGCLAG`, `_gcl_ag` | `gbraid` |
| `FPGCLGB`, `_gcl_gb` | `wbraid` |

**Do not always map `preferential_click_id` to `gclid`.** Depending on your Google Ads tag or API integration, configure conditional mapping so the winning ID goes to its corresponding field. For Google Ads offline click-conversion uploads, typically send only the selected identifier field. Read Google's [offline conversion documentation](https://developers.google.com/google-ads/api/docs/conversions/upload-offline) for your integration.

If an ID is missing, its field is `null`; if none are available, both preferential fields are `null`. The template **does not retrieve database records, read browser cookies, or check advertising consent**; those responsibilities remain with your existing lookup and conversion-tag consent setup. The optional logging feature requires GTM logging and container data permissions.

## Logging

Under **Logging Preferences**, choose **Disable Logging**, **Debug Mode** (default), or **Always Log**. Logs show the number of available IDs and winning source cookie, never the click ID itself.

## Developer

**Javier Garijo** — [GitHub](https://github.com/javier-garijo-gtm) · **Fixed Analytics™**
