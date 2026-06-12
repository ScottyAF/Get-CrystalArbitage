# ⚔ FFXIV Crystal Arbitrage Scanner

A PowerShell WPF desktop application for finding cross-world market board arbitrage opportunities on the **Crystal datacenter** in Final Fantasy XIV. Scans all marketable items, identifies price gaps between Crystal worlds, and surfaces deals where you can buy cheap on one world and sell for profit on your home world.

---

## Screenshots

> _Dark themed WPF GUI — sortable results grid, live progress bar, configurable filters_

---

## Features

- **Scans all ~3,800 marketable items** on Crystal every run — no random sampling, fully consistent results
- **Parallel API requests** (16 threads) keep full scans around 60 seconds
- **Trimmed, time-weighted average sell price** — removes outlier panic sales and stale overpriced listings, weighting recent sales more heavily to reflect the current market
- **Buy-world depth check** — confirms how many units are actually available within a configurable price band before flagging a deal, so you don't travel for a single item
- **Home-world sales velocity** — filters on how fast the item sells specifically on your world, not the datacenter-wide rate
- **Avg Profit and Max Profit** columns — shows both the realistic return based on average sales and the potential ceiling if you catch a patient buyer
- **CSV export** for tracking deals over time
- Pulls item names from **XIVAPI v2** (current patch data) with Garland Tools as fallback

---

## Requirements

- **Windows** (WPF requires Windows)
- **PowerShell 7.0+** — [Download here](https://github.com/PowerShell/PowerShell/releases)
- Internet connection to reach [universalis.app](https://universalis.app), [v2.xivapi.com](https://v2.xivapi.com), and [garlandtools.org](https://www.garlandtools.org)
- No API key required — all APIs used are free and public

---

## Installation

```powershell
# Clone the repo
git clone https://github.com/YOUR_USERNAME/ffxiv-crystal-arbitrage.git
cd ffxiv-crystal-arbitrage

# Allow local script execution if needed (run once)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## Usage

```powershell
.\Get-CrystalArbitrage-GUI.ps1
```

A window will open. Set your parameters in the left panel and click **▶ Start Scan**. Results populate live as the scan progresses. Click any column header to sort. Use **⬇ Export CSV** to save results.

---

## Parameters

All parameters are configurable in the GUI settings panel:

| Parameter | Default | Description |
|---|---|---|
| Home World | `Coeurl` | Your home world — where you sell. Must be a Crystal world. |
| Top Items to Analyse | `2000` | After sorting all items by DC sale velocity, how many to run the full listing analysis on. |
| Min Profit / Unit | `5,000 gil` | Minimum profit per unit after market board tax. |
| Min Profit Margin | `20%` | Minimum profit margin after tax. |
| Min Sales / Day | `5` | Minimum NQ sales per day on your **home world** (not DC-wide). Ensures you can actually move the stock. |
| Market Board Tax | `5%` | Your home world's market board tax rate (0–5%). Check in-game. |
| Buy Price Band | `10%` | Listings within this % above the cheapest price count toward available units. Captures realistic purchasable stock. |
| Min Units Available | `10` | Minimum units available within the price band on the buy world. |

---

## How It Works

The scan runs in five stages:

```
1. World list          — maps world IDs to names from Universalis
2. Marketable items    — fetches all ~3,800 tradeable item IDs
3. Item names          — resolves names in parallel from XIVAPI v2
4a. Aggregated data    — fetches DC-cheapest listing + sale velocity for all items (parallel)
                         → sorts by velocity, keeps top N for deep analysis
4b. Home-world data    — fetches current listings + recent sale history for your world (parallel)
                         → calculates trimmed time-weighted average sell price and local velocity
4c. Buy-world depth    — for pre-filtered profitable candidates only, fetches buy-world listings
                         → counts units available within the price band
5. Analysis            — computes avg/max profit, applies all filters, ranks by avg profit
```

### Pricing methodology

Rather than using the current cheapest listing as the sell price (which can be a single undercutter at 1% of market value), the scanner uses a **trimmed, time-weighted average of recent sale history**:

1. Collects all NQ sales from the last 50 transactions on your home world
2. Sorts by price and trims the bottom 10% and top 10% to remove outliers
3. Averages the remaining sales, weighting each by **quantity sold × recency** (sales from today count up to 10× more than sales from 7 days ago)

This gives a realistic "what does this item actually sell for" price that's resistant to manipulation and reflects current market conditions.

**Max Sell** uses the highest price in the trimmed range — the ceiling you could achieve with a patient listing.

---

## Crystal Datacenter Worlds

| World | World | World | World |
|---|---|---|---|
| Balmung | Brynhildr | Coeurl | Diabolos |
| Goblin | Malboro | Mateus | Zalera |

---

## API Usage

This tool uses three free, public APIs with no authentication required:

| API | Purpose |
|---|---|
| [universalis.app](https://universalis.app) | Market board data |
| [v2.xivapi.com](https://v2.xivapi.com) | Item names (current patch) |
| [garlandtools.org](https://www.garlandtools.org) | Item name fallback |

The scanner uses 16 parallel threads and makes roughly 80–120 total requests per full scan, well within Universalis's documented rate limit. Please don't drastically increase thread count — these are community-run free services.

---

## Tips

- **Run just before you travel** — prices shift constantly. A deal found 20 minutes ago may already be gone.
- **Check the Units column** — a deal with 200 units available is far more valuable than one with 5.
- **Vol/Day matters** — high profit means nothing if the item sells once a week. Filter for items your world moves regularly.
- **Max Profit is aspirational** — it reflects the highest recent sale in the trimmed range. Avg Profit is what you should plan around.
- **Tax rate** — check your city-state in-game. Most players have 3–5% depending on Free Company buffs and retainer placement.
- Lower **Min Sales/Day** if you're comfortable holding items longer. Higher-value gear with lower velocity can still be excellent flips.

---

## Contributing

Pull requests welcome. Some areas that could use improvement:

- HQ item support (currently NQ only)
- Multi-datacenter support (Aether, Primal, etc.)
- Price history charts per item
- Notification/alert mode for specific items

---

## Disclaimer

This tool queries publicly available market board data via the Universalis crowdsourced API. It does not interact with the Final Fantasy XIV game client, inject into any process, or violate the FFXIV Terms of Service. All data is read-only and sourced from player-submitted market board snapshots.

FINAL FANTASY XIV is a registered trademark of Square Enix Holdings Co., Ltd.

---

## License

This project is licensed under the **GNU General Public License v3.0** — see [LICENSE](LICENSE) for details.
