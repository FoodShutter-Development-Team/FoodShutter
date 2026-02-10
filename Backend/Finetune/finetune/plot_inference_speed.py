import json
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import numpy as np

# Load data
with open("visualize_results/inference_results.json") as f:
    inference_data = json.load(f)

with open("gemini_results/gemini_results.json") as f:
    gemini_data = json.load(f)

# Extract inference times (ms)
base_times = [r["base_inference_ms"] for r in inference_data if "base_inference_ms" in r]
ft_times = [r["finetuned_inference_ms"] for r in inference_data if "finetuned_inference_ms" in r]

# Build a lookup for gemini times by image name
gemini_lookup = {r["image"]: r["gemini_inference_ms"] for r in gemini_data if "gemini_inference_ms" in r}

# Align gemini times with the same images as base/ft
gemini_times = [gemini_lookup[r["image"]] for r in inference_data if r["image"] in gemini_lookup]

print(f"Samples — Base: {len(base_times)}, Fine-tuned: {len(ft_times)}, Gemini: {len(gemini_times)}")
print(f"Base   — median: {np.median(base_times):.0f} ms, mean: {np.mean(base_times):.0f} ms")
print(f"FT     — median: {np.median(ft_times):.0f} ms, mean: {np.mean(ft_times):.0f} ms")
print(f"Gemini — median: {np.median(gemini_times):.0f} ms, mean: {np.mean(gemini_times):.0f} ms")

# Convert to seconds for readability
data = [
    [t / 1000 for t in base_times],
    [t / 1000 for t in ft_times],
    [t / 1000 for t in gemini_times],
]
labels = ["Base Qwen", "Fine-tuned Qwen", "Gemini Flash"]
colors = ["#4C72B0", "#55A868", "#C44E52"]

fig, ax = plt.subplots(figsize=(9, 6))

bp = ax.boxplot(
    data,
    patch_artist=True,
    notch=False,
    widths=0.45,
    medianprops=dict(color="white", linewidth=2.5),
    whiskerprops=dict(linewidth=1.5),
    capprops=dict(linewidth=1.5),
    flierprops=dict(marker="o", markersize=5, alpha=0.6),
)

for patch, color in zip(bp["boxes"], colors):
    patch.set_facecolor(color)
    patch.set_alpha(0.8)

for flier, color in zip(bp["fliers"], colors):
    flier.set_markerfacecolor(color)
    flier.set_markeredgecolor(color)

# Overlay individual data points (jittered)
np.random.seed(42)
for i, (d, color) in enumerate(zip(data, colors), start=1):
    jitter = np.random.normal(0, 0.07, size=len(d))
    ax.scatter(i + jitter, d, alpha=0.35, s=20, color=color, zorder=3)

# Annotate medians
for i, d in enumerate(data, start=1):
    med = np.median(d)
    ax.text(i, med + 0.15, f"{med:.1f}s", ha="center", va="bottom", fontsize=9,
            fontweight="bold", color="black")

ax.set_xticks([1, 2, 3])
ax.set_xticklabels(labels, fontsize=11)
ax.set_ylabel("Inference Time (seconds)", fontsize=12)
ax.set_title("Inference Speed Comparison\n(50 food image samples)", fontsize=13, fontweight="bold")
ax.yaxis.grid(True, linestyle="--", alpha=0.5)
ax.set_axisbelow(True)

# Stats table below the plot
col_labels = ["Metric", "Base Qwen", "Fine-tuned Qwen", "Gemini"]
rows = [
    ["Median (s)", f"{np.median(data[0]):.2f}", f"{np.median(data[1]):.2f}", f"{np.median(data[2]):.2f}"],
    ["Mean (s)",   f"{np.mean(data[0]):.2f}",   f"{np.mean(data[1]):.2f}",   f"{np.mean(data[2]):.2f}"],
    ["Std (s)",    f"{np.std(data[0]):.2f}",    f"{np.std(data[1]):.2f}",    f"{np.std(data[2]):.2f}"],
    ["Min (s)",    f"{np.min(data[0]):.2f}",    f"{np.min(data[1]):.2f}",    f"{np.min(data[2]):.2f}"],
    ["Max (s)",    f"{np.max(data[0]):.2f}",    f"{np.max(data[1]):.2f}",    f"{np.max(data[2]):.2f}"],
]
table = ax.table(
    cellText=rows,
    colLabels=col_labels,
    loc="bottom",
    bbox=[0, -0.52, 1, 0.42],
)
table.auto_set_font_size(False)
table.set_fontsize(9)
for (row, col), cell in table.get_celld().items():
    if row == 0:
        cell.set_facecolor("#333333")
        cell.set_text_props(color="white", fontweight="bold")
    elif col == 0:
        cell.set_facecolor("#f0f0f0")
    else:
        cell.set_facecolor("#fafafa")
    cell.set_edgecolor("#cccccc")

plt.subplots_adjust(bottom=0.38)
plt.tight_layout()

out_path = "visualize_results/inference_speed_boxplot.png"
plt.savefig(out_path, dpi=150, bbox_inches="tight")
print(f"Saved: {out_path}")
