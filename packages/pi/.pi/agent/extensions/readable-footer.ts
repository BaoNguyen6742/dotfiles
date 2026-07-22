import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

function formatTokens(value: number): string {
	if (value >= 1_000_000) {
		return `${(value / 1_000_000).toFixed(1).replace(/\.0$/, "")}M`;
	}
	if (value >= 1_000) {
		return `${(value / 1_000).toFixed(1).replace(/\.0$/, "")}K`;
	}
	return String(value);
}

function installFooter(ctx: ExtensionContext, pi: ExtensionAPI): void {
	ctx.ui.setFooter((tui, theme, footerData) => {
		const unsubscribe = footerData.onBranchChange(() => tui.requestRender());

		return {
			dispose: unsubscribe,
			invalidate() {},
			render(width: number): string[] {
				let input = 0;
				let output = 0;
				let cacheRead = 0;
				let cost = 0;
				let latestCacheHit: number | undefined;

				for (const entry of ctx.sessionManager.getBranch()) {
					if (entry.type !== "message" || entry.message.role !== "assistant") continue;
					const message = entry.message as AssistantMessage;
					const usage = message.usage;
					input += usage.input;
					output += usage.output;
					cacheRead += usage.cacheRead;
					cost += usage.cost.total;

					const promptTokens = usage.input + usage.cacheRead + usage.cacheWrite;
					if (promptTokens > 0) {
						latestCacheHit = (usage.cacheRead / promptTokens) * 100;
					}
				}

				const context = ctx.getContextUsage();
				const contextPercent = context?.percent == null ? "?" : `${context.percent.toFixed(1)}%`;
				const contextText = context
					? `${formatTokens(context.tokens)} / ${formatTokens(context.contextWindow)} (${contextPercent})`
					: "UNKNOWN";
				const cacheHitText = latestCacheHit === undefined ? "N/A" : `${latestCacheHit.toFixed(1)}%`;
				const subscription = ctx.model && ctx.modelRegistry.isUsingOAuth(ctx.model) ? " (SUBSCRIPTION)" : "";
				const branch = footerData.getGitBranch();

				const separator = theme.fg("dim", "  │  ");
				const headingLabels = ["◆ TOKENS", "◇ SESSION", "⌂ DIRECTORY"];
				const headingWidth = Math.max(...headingLabels.map(visibleWidth));
				const formatHeading = (label: string): string => theme.fg(
					"accent",
					theme.bold(label + " ".repeat(headingWidth - visibleWidth(label))),
				);
				const cacheHitColor: "muted" | "success" | "warning" | "error" = latestCacheHit === undefined
					? "muted"
					: latestCacheHit >= 90
						? "success"
						: latestCacheHit >= 50
							? "warning"
							: "error";
				const contextColor: "muted" | "success" | "warning" | "error" = context?.percent == null
					? "muted"
					: context.percent > 90
						? "error"
						: context.percent > 70
							? "warning"
							: "success";

				const tokenLine = [
					formatHeading("◆ TOKENS"),
					`${theme.fg("muted", "⇧ INPUT")} ${theme.fg("text", formatTokens(input))}`,
					`${theme.fg("muted", "⇩ OUTPUT")} ${theme.fg("text", formatTokens(output))}`,
					`${theme.fg("muted", "↻ CACHE")} ${theme.fg("text", formatTokens(cacheRead))}`,
					`${theme.fg("muted", "◉ HIT")} ${theme.fg(cacheHitColor, cacheHitText)}`,
				].join(separator);

				const costText = `$${cost.toFixed(3)}${subscription}`;
				const thinkingLevel = pi.getThinkingLevel();
				const thinkingColor: "dim" | "muted" | "accent" | "warning" | "error" =
					thinkingLevel === "off"
						? "dim"
						: thinkingLevel === "minimal" || thinkingLevel === "low"
							? "muted"
							: thinkingLevel === "medium"
								? "accent"
								: thinkingLevel === "max"
									? "error"
									: "warning";
				const modelAndThinking = [
					`${theme.fg("muted", "⚡ MODEL")} ${theme.fg("accent", ctx.model?.id ?? "NONE")}`,
					`${theme.fg("muted", "✦ THINKING")} ${theme.fg(thinkingColor, thinkingLevel.toUpperCase())}`,
				].join("  ");
				const contextLine = [
					formatHeading("◇ SESSION"),
					`${theme.fg("muted", "▣ CONTEXT")} ${theme.fg(contextColor, contextText)}`,
					modelAndThinking,
					`${theme.fg("muted", "◆ COST")} ${theme.fg("warning", costText)}`,
				].join(separator);
				const directoryLine = [
					formatHeading("⌂ DIRECTORY"),
					theme.fg("text", ctx.cwd),
					branch ? `${theme.fg("muted", "⑂ BRANCH")} ${theme.fg("success", branch)}` : undefined,
				].filter((part): part is string => Boolean(part)).join(separator);

				return [
					truncateToWidth(tokenLine, width),
					truncateToWidth(contextLine, width),
					truncateToWidth(directoryLine, width),
				];
			},
		};
	});
}

export default function readableFooter(pi: ExtensionAPI) {
	let enabled = true;

	pi.on("session_start", (_event, ctx) => {
		if (enabled) installFooter(ctx, pi);
	});

	pi.on("thinking_level_select", (_event, ctx) => {
		if (enabled) installFooter(ctx, pi);
	});

	pi.registerCommand("readable-footer", {
		description: "Toggle the uppercase, readable session footer",
		handler: async (_args, ctx) => {
			enabled = !enabled;
			if (enabled) {
				installFooter(ctx, pi);
				ctx.ui.notify("READABLE FOOTER ENABLED", "info");
			} else {
				ctx.ui.setFooter(undefined);
				ctx.ui.notify("DEFAULT FOOTER RESTORED", "info");
			}
		},
	});
}
