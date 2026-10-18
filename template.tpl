___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google's Community
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
  "description": "Server GTM variable that selects the preferential Google Ads click ID using GCLID > GBRAID > WBRAID priority and identifies its source cookie.",
  "categories": [
    "ATTRIBUTION",
    "CONVERSIONS",
    "UTILITY"
  ],
  "containerContexts": [
    "SERVER"
  ]
}

___TEMPLATE_PARAMETERS___

[
  {
    "type": "GROUP",
    "name": "clickIdsGroup",
    "displayName": "Click ID configuration",
    "groupStyle": "ZIPPY_OPEN",
    "subParams": [
      {
        "type": "SIMPLE_TABLE",
        "name": "clickIdInputs",
        "displayName": "Click IDs from database",
        "help": "Choose one of the six cookie sources and select the server GTM variable containing its click ID. Add as many rows as needed; do not enter the entire cookie value.",
        "newRowButtonText": "Add click ID",
        "simpleTableColumns": [
          {
            "type": "SELECT",
            "name": "clickIdType",
            "displayName": "Click ID type",
            "defaultValue": "",
            "selectItems": [
              {
                "value": "",
                "displayValue": "Choose click ID type"
              },
              {
                "value": "FPGCLAW",
                "displayValue": "FPGCLAW"
              },
              {
                "value": "_gcl_aw",
                "displayValue": "_gcl_aw"
              },
              {
                "value": "FPGCLAG",
                "displayValue": "FPGCLAG"
              },
              {
                "value": "_gcl_ag",
                "displayValue": "_gcl_ag"
              },
              {
                "value": "FPGCLGB",
                "displayValue": "FPGCLGB"
              },
              {
                "value": "_gcl_gb",
                "displayValue": "_gcl_gb"
              }
            ],
            "macrosInSelect": false,
            "isUnique": true
          },
          {
            "type": "TEXT",
            "name": "clickIdValue",
            "displayName": "Click ID value (variable)",
            "defaultValue": "",
            "valueHint": "e.g. {{DB - GCLID}}"
          }
        ]
      },
      {
        "type": "LABEL",
        "name": "priorityHelp",
        "displayName": "Priority: FPGCLAW > _gcl_aw > FPGCLAG > _gcl_ag > FPGCLGB > _gcl_gb. GCLID wins over GBRAID/WBRAID; first-party wins within the same ID type."
      }
    ],
    "help": "Add one row per click ID available from your database. The value must be the click ID itself, not a full cookie string. Row order does not change priority. Works whenever a tag evaluates this variable, on any event."
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
            "displayValue": "Debug Mode",
            "help": "Only log when server GTM Preview or Debug mode is active."
          },
          {
            "value": "always",
            "displayValue": "Always Log",
            "help": "Log in both Preview and production."
          }
        ],
        "help": "Logs the number of available click IDs and the winning source cookie, never the click ID values. Default: Debug Mode."
      }
    ]
  }
]

___SANDBOXED_JS_FOR_SERVER___

// Preferential Google Ads Click ID - Fixed Analytics™
// Developer: Javier Garijo (github.com/javier-garijo-gtm)
// Receives click IDs from user-selected GTM variables; does not fetch cookies.
// Input table row order does not affect identifier priority.

// Logging deliberately excludes actual click IDs to prevent identifier leakage.
var logToConsole = require('logToConsole');
var getContainerVersion = require('getContainerVersion');

function isLoggingEnabled() {
  var preference = data.loggingPreference || 'debug';
  if (preference === 'none') return false;
  if (preference === 'always') return true;
  var version = getContainerVersion();
  return !!(version && (version.debugMode || version.previewMode));
}

function cleanClickId(value) {
  // Click identifiers are strings. Do not stringify absent values into IDs.
  if (typeof value !== 'string') return null;
  var cleaned = value.trim();
  if (!cleaned) return null;
  if (cleaned === 'undefined' || cleaned === 'null') return null;
  return cleaned;
}

var result = {
  fp_gclid: null,
  fp_gbraid: null,
  fp_wbraid: null,
  gclid: null,
  gbraid: null,
  wbraid: null
};

var sourceFields = {
  'FPGCLAW': 'fp_gclid',
  '_gcl_aw': 'gclid',
  'FPGCLAG': 'fp_gbraid',
  '_gcl_ag': 'gbraid',
  'FPGCLGB': 'fp_wbraid',
  '_gcl_gb': 'wbraid'
};

var rows = data.clickIdInputs || [];
for (var i = 0; i < rows.length; i++) {
  var row = rows[i];
  if (!row) continue;
  var field = sourceFields[row.clickIdType];
  if (!field || result[field] !== null) continue;
  var id = cleanClickId(row.clickIdValue);
  if (id !== null) result[field] = id;
}

// Identifier type outranks source; first-party outranks JS within that type.
var priority = [
  ['fp_gclid', 'FPGCLAW'],
  ['gclid', '_gcl_aw'],
  ['fp_gbraid', 'FPGCLAG'],
  ['gbraid', '_gcl_ag'],
  ['fp_wbraid', 'FPGCLGB'],
  ['wbraid', '_gcl_gb']
];

result.preferential_click_id = null;
result.preferential_click_id_type = null;
for (var j = 0; j < priority.length; j++) {
  var candidate = priority[j];
  if (result[candidate[0]] !== null) {
    result.preferential_click_id = result[candidate[0]];
    result.preferential_click_id_type = candidate[1];
    break;
  }
}

if (isLoggingEnabled()) {
  var availableCount = 0;
  var fieldsToCount = ['fp_gclid', 'fp_gbraid', 'fp_wbraid', 'gclid', 'gbraid', 'wbraid'];
  for (var k = 0; k < fieldsToCount.length; k++) {
    if (result[fieldsToCount[k]] !== null) availableCount++;
  }
  logToConsole('Preferential Google Ads Click ID - Fixed Analytics™: ' +
    'available IDs=' + availableCount +
    ', selected cookie=' + (result.preferential_click_id_type || 'none'));
}

return result;

___SERVER_PERMISSIONS___

[
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
This is a server-side variable that accepts previously extracted click ID strings in a two-column simple table (type, value). It does not connect to a database or read cookies.
All six supported sources: FPGCLAW, _gcl_aw, FPGCLAG, _gcl_ag, FPGCLGB, _gcl_gb.
Priority: FPGCLAW > _gcl_aw > FPGCLAG > _gcl_ag > FPGCLGB > _gcl_gb.
Output: fp_gclid, fp_gbraid, fp_wbraid, gclid, gbraid, wbraid, preferential_click_id, preferential_click_id_type.
Missing inputs are null. Returns an object on all event types when evaluated, with no database access, HTTP requests, caching, or cookie access. Optional logging uses server logging and container metadata permissions; actual click IDs are never written to logs. Default: Debug Mode. No embedded tests.
Google Ads conversion integrations must map the winning source to the correct gclid/gbraid/wbraid parameter and independently enforce applicable consent. Preferred does not mean most recent click.
