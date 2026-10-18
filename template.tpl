___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.

___INFO___

{
  "type": "MACRO",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "Preferential Google Ads Click ID - Fixed Analytics™",
  "description": "Fetches six click IDs and selects a preferential ID by priority, with its source cookie. Checks ad_storage consent.",
  "categories": [
    "ATTRIBUTION",
    "ADVERTISING",
    "UTILITY"
  ],
  "containerContexts": [
    "WEB"
  ]
}

___TEMPLATE_PARAMETERS___

[
  {
    "type": "LABEL",
    "name": "output_description",
    "displayName": "Returns six click IDs plus preferential_click_id (ID only) and preferential_click_id_type (exact cookie name). Priority: FPGCLAW > _gcl_aw > FPGCLAG > _gcl_ag > FPGCLGB > _gcl_gb. Missing IDs: null. Requires ad_storage consent."
  },
  {
    "type": "LABEL",
    "name": "developer_attribution",
    "displayName": "Developed by Javier Garijo | Fixed Analytics™ | github.com/javier-garijo-gtm"
  },
  {
    "type": "GROUP",
    "name": "loggingSettings",
    "displayName": "Logging Preferences",
    "groupStyle": "ZIPPY_CLOSED",
    "subParams": [
      {
        "type": "RADIO",
        "name": "loggingPreference",
        "displayName": "Logging Preferences",
        "simpleValueType": true,
        "defaultValue": "debug",
        "radioItems": [
          {
            "value": "none",
            "displayValue": "Disable Logging",
            "help": "Never log diagnostics."
          },
          {
            "value": "debug",
            "displayValue": "Debug Mode (Default)",
            "help": "Log only in GTM Preview/Debug."
          },
          {
            "value": "always",
            "displayValue": "Always Log",
            "help": "Log in Preview and production."
          }
        ],
        "help": "Logs only consent outcome, number of available IDs, and preferred source cookie. Never logs actual click ID values."
      }
    ]
  }
]

___SANDBOXED_JS_FOR_WEB_TEMPLATE___

// Preferential Google Ads Click ID - Fixed Analytics™
// Developer: Javier Garijo (github.com/javier-garijo-gtm)
// Cookie retrieval and GBRAID parsing replicate the original working fetcher.
// Checks Google Consent Mode ad_storage before accessing cookies.
const isConsentGranted = require('isConsentGranted');
const getCookieValues = require('getCookieValues');
const logToConsole = require('logToConsole');
const getContainerVersion = require('getContainerVersion');

// Logging is optional and never includes the click ID values.
function loggingIsEnabled() {
  var setting = data.loggingPreference || 'debug';
  if (setting === 'none') return false;
  if (setting === 'always') return true;
  var container = getContainerVersion();
  return !!(container && (container.debugMode || container.previewMode));
}

if (!isConsentGranted('ad_storage')) {
  if (loggingIsEnabled()) {
    logToConsole('Preferential Google Ads Click ID - Fixed Analytics™: ad_storage denied; cookies not read');
  }
  return undefined;
}

// The original working GCLID method: read the first cookie value and
// take the last dot-separated section, e.g. GCL.123456.CLICK_ID.
function lastDotSegment(cookieName) {
  var values = getCookieValues(cookieName);
  if (!values || !values.length) return null;
  var raw = values[0];
  if (typeof raw !== 'string') return null;
  var parts = raw.split('.');
  if (parts.length < 2) return null;
  return parts[parts.length - 1] || null;
}

// The original working GBRAID method: read values[0], find 'k',
// then take everything until '$', e.g. 2.1.kOOPS$i1792264191 -> OOPS.
// Used for both FP and JS braid cookies, including _gcl_gb (WBRAID).
function idAfterK(cookieName) {
  var values = getCookieValues(cookieName);
  if (!values || !values.length) return null;
  var raw = values[0];
  if (typeof raw !== 'string') return null;
  var kIndex = raw.indexOf('k');
  if (kIndex === -1) return null;
  var afterK = raw.substring(kIndex + 1);
  var dollarIndex = afterK.indexOf('$');
  var id = (dollarIndex === -1) ? afterK : afterK.substring(0, dollarIndex);
  return id || null;
}

// Preserve the working last-dot GCLID behavior; support the newer 2.x.k
// form too if an FP GCLID cookie uses that envelope.
function readGclid(cookieName) {
  var values = getCookieValues(cookieName);
  if (!values || !values.length) return null;
  var raw = values[0];
  if (typeof raw !== 'string') return null;
  if (raw.indexOf('2.') === 0 && raw.indexOf('.k') !== -1) {
    return idAfterK(cookieName);
  }
  return lastDotSegment(cookieName);
}

// Most WBRAID cookies use the same 2.x.k format as GBRAID.
// Retain compatibility with the older GCL.timestamp.id format.
function readWbraid(cookieName) {
  var values = getCookieValues(cookieName);
  if (!values || !values.length) return null;
  var raw = values[0];
  if (typeof raw !== 'string') return null;
  if (raw.indexOf('GCL.') === 0) return lastDotSegment(cookieName);
  return idAfterK(cookieName);
}

// Each field is fetched on variable evaluation, directly through the same
// getCookieValues API and first-entry parsing used by the working template.
var result = {
  fp_gclid: readGclid('FPGCLAW'),
  fp_gbraid: idAfterK('FPGCLAG'),
  fp_wbraid: readWbraid('FPGCLGB'),
  gclid: readGclid('_gcl_aw'),
  gbraid: idAfterK('_gcl_ag'),
  wbraid: readWbraid('_gcl_gb')
};

var preferred = null;
var preferredType = null;
if (result.fp_gclid !== null) {
  preferred = result.fp_gclid;
  preferredType = 'FPGCLAW';
} else if (result.gclid !== null) {
  preferred = result.gclid;
  preferredType = '_gcl_aw';
} else if (result.fp_gbraid !== null) {
  preferred = result.fp_gbraid;
  preferredType = 'FPGCLAG';
} else if (result.gbraid !== null) {
  preferred = result.gbraid;
  preferredType = '_gcl_ag';
} else if (result.fp_wbraid !== null) {
  preferred = result.fp_wbraid;
  preferredType = 'FPGCLGB';
} else if (result.wbraid !== null) {
  preferred = result.wbraid;
  preferredType = '_gcl_gb';
}
result.preferential_click_id = preferred;
result.preferential_click_id_type = preferredType;
if (loggingIsEnabled()) {
  var availableCount = 0;
  var fieldsToCount = ['fp_gclid', 'fp_gbraid', 'fp_wbraid', 'gclid', 'gbraid', 'wbraid'];
  for (var i = 0; i < fieldsToCount.length; i++) {
    if (result[fieldsToCount[i]] !== null) availableCount++;
  }
  logToConsole('Preferential Google Ads Click ID - Fixed Analytics™: ' +
    'ad_storage check passed, available IDs=' + availableCount +
    ', preferred cookie=' + (result.preferential_click_id_type || 'none'));
}

return result;

___WEB_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "get_cookies",
        "versionId": "1"
      },
      "param": [
        {
          "key": "cookieAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "cookieNames",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "FPGCLAW"
              },
              {
                "type": 1,
                "string": "FPGCLAG"
              },
              {
                "type": 1,
                "string": "FPGCLGB"
              },
              {
                "type": 1,
                "string": "_gcl_aw"
              },
              {
                "type": 1,
                "string": "_gcl_ag"
              },
              {
                "type": 1,
                "string": "_gcl_gb"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_consent",
        "versionId": "1"
      },
      "param": [
        {
          "key": "consentTypes",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "consentType"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "ad_storage"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "all"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_container_data",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  }
]

___TESTS___

scenarios: []

___NOTES___

Preferential Google Ads Click ID - Fixed Analytics™. Developer: Javier Garijo.
Returns eight fields: six source IDs plus preferential_click_id (click ID only) and preferential_click_id_type (source cookie name).
Preference: FPGCLAW > _gcl_aw > FPGCLAG > _gcl_ag > FPGCLGB > _gcl_gb.
Cookie access and GBRAID extraction intentionally replicate the original working template: first cookie value, parse after k to $.
Uses get_cookies permission for the six specific required cookies. Checks ad_storage; no persisted storage or explicit caching.
Null for absent IDs; undefined if ad_storage consent is denied. No embedded tests.

Logging Preferences: Disable Logging, Debug Mode (default), Always Log. Logs include consent result, available-ID count, and winning cookie name only; no click ID values. Additional permissions: logging (all environments) and read_container_data for Preview/Debug detection.
