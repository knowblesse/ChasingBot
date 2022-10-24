# Fb
- Folder for fiberphotometry analysis scripts

## Functions
- [**`autoDetectExpType.m`** ](#autoDetectExpType)
- [**`drawFibFigure.m`** ](#drawFibFigure)
- [**`loadFibData.m`** ](#loadFibData)
- [**`TDTbin2mat.m`** ](#TDTbin2mat)

---
# **autoDetectExpType** 
## Usage
`expType = autoDetectExpType(Path)`

`expType = autoDetectExpType(Path, verbose)`

## Description
 Get experiment type from the parsed Tank name
 
`expType = autoDetectExpType(Path)` : Get Experiment type of the Tank in path. Verbosely print outputs.

`expType = autoDetectExpType(Path, verbose)` : If `false` is given to `verbose`, print no output.

## Input Parameters
### Path
**string**. Path to the Tank
### verbose
**boolean**. If true, vervally print output. If false, run silently.

## Output Parameters
### expType
**string**. Either **"Conditioning"**, **"Extinction"**, **"Retention"**, and **"Renewal""**.
If the input tank does not belong to these types, raise error.

---
# **drawFibFigure**
## Usage
`drawFibFigure()` : Draw fiberphotometry figure after selecting the Tank using UI.

`drawFibFigure(Path)` : Draw with predefined Tank path.

`drawFibFigure(Path, Name, Value)` : Draw with options changed
> **Example**
> 
> Draw the figure without any output message : 
> 
> `drawFibFigure('C:\Data\ToneFib-220920-111234_fpm10_con', 'verbose', false);`
> 
> Draw the figure during 5 sec before and 30 sec after the CS onset, with the z score baseline correction. The baseline is calculated from the beginning of the session :
> 
> `drawFibFigure('C:\Data\ToneFib-220920-111234_fpm10_con','timewindow', [-5, 30], 'baseline_correction', 'z', 'baseline_mode', 'whole');`


## Description
 Automatically draw fiberphotometry delta value

## Input Parameters
### Path
**String**. Path to the Tank. If not provided, UI for selecting dir will be opened.
### Name-Value pairs
#### `"verbose"`
**Boolean**. If false, print no output. Default `true`

#### `"timewindow"`
**Double array (1,2)**. Draw graph `timewindow(1)` seconds from CS to `timewindow(2)` seconds from CS. Default `[-5, 20]`

#### `"us_offset"`
**Double scalar**. US starts `usoffset` seconds before the CS ends. Default `2.5`

#### `"baseline_correction"`
**String**. Three values are possible "z", "zero", and "none". Default `"none"`
- `"z"` : Use zscore method.
- `"zero"` : Subtract mean baseline to move signal to zero.
- `"none"` : No baseline correction.

#### `"baseline_mode"`
**String**. Decide how to calculate the baseline. Two values are possible `"whole"` and `"trial"`. Default `"trial"`
- `"whole"` : Get baseline from the beginning of the session. Ignore first `baseline_whole_ignore_duration` seconds of the data, and use  `baseline_duration` seconds as baseline. For example, if `baseline_whole_ignore_duration` is set as 30, and `baseline_duration` is set as 60, session's 30 sec ~ 90 sec data will be used as the baseline.
- `"trial"` : For each trial, use `baselineduration` seconds from the `timewindow(1)` as the baseline. Not from the CS, it's from the timewindow.

---
#### `"baseline_trial_duration"`
**Double scalar**. Length of the signal in second to use as the baseline in `"trial"` baseline correction mode.

#### `"baseline_trial_ignore_duration"`
**Double scalar**. Length of the signal to ignore in `"trial"` baseline correction mode.

#### `"baseline_whole_duration"`
**Double scalar**. Length of the signal in second to use as the baseline in `"whole"` baseline correction mode.

#### `"baseline_whole_ignore_duration"`
**Double scalar**. Length of the signal to ignore in `"whole"` baseline correction mode.

#### `"baseline_mix_duration"`
**[1,2] Double vector**. Length of the signal in second to use as the baseline in `"mix"` baseline correction mode. The first value is for mean correction as in `"trial"` mode and the second value is for std correction as in `"whole"` mode.

#### `"filter"`
**Double scalar**. If non-zero, apply moving average filter to the signal. The moving average filter with `filter * fs` will be used.

#### `"draw_total_result"`
**Boolean**. If false, only draw the signal from each trial. Default is `true`.

#### `"draw_ribbon_result"`
**Boolean**. If true, draw the ribbon graph. Default is `true`.

#### `"extinction_trials_per_graph"`
**Double scalar**. Number of trials to plot in one graph in Extinction dataset. Default is `6`. Note that extinction CS number must be dividable with this value. 

---

# **loadFibData** 
## Usage
`Data = loadFibData()`

`Data = loadFibData(Path)`

`Data = loadFibData(Path, Name, Value)`

## Description
 Load fiberphotometry data.
 
`Data = loadFibData()` : Load data after selecting the Tank using UI

`Data = loadFibData(Path)` : Load data with specified Tank location

`Data = loadFibData(Path, Name, Value)` : Load data with extra options.

## Input Parameters

### Path
**string**. Path to the Tank

### Name-Value pairs
#### `"verbose"`
Boolean. If false, print no output. Default `true`

## Output Parameters

### Data
**Struct**. Contains **path**, **cs**, **fs**, **x465**, **x405**, and **delta**.

---

# **TDTbin2mat** 
See official TDT Matlab SDK.

This script is partially modified from the original script.
