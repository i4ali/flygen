# FlyGen Profit Analysis

## Overview

This document analyzes FlyGen's profitability including revenue, costs, and customer acquisition cost (CAC).

---

## 1. Revenue Model

### 1.1 Credit Pack Pricing (Current Implementation)

| Pack | Credits | Price (USD) | Price per Credit |
|------|---------|-------------|------------------|
| 10 Credits | 10 | $1.99 | $0.199 |
| 25 Credits | 25 | $3.99 | $0.160 |
| 50 Credits | 50 | $5.99 | $0.120 |

*Note: Prices are configured in App Store Connect. Actual displayed prices may vary by region.*

### 1.2 Credit Usage

| Action | Credits Used |
|--------|--------------|
| Generate flyer | 1 |
| Refine flyer | 1 |
| Resize flyer | 1 |

### 1.3 Free Credits

- New users receive **3 free credits** on first launch
- Free credits are a customer acquisition cost (see below)

---

## 2. Cost Structure

### 2.1 Per-Generation Costs (API)

FlyGen uses **Gemini 2.5 Flash** via OpenRouter for image generation.

| Cost Component | Amount |
|----------------|--------|
| Gemini 2.5 Flash (via OpenRouter) | ~$0.04 per generation |
| Cloudflare Worker (proxy) | Free tier / negligible |

**Estimated API cost per credit used: ~$0.04**

### 2.2 Apple's Commission

Apple takes **30%** of all in-app purchases (15% for small business program if qualified).

| Commission Rate | Scenario |
|-----------------|----------|
| 30% | Standard rate |
| 15% | Small Business Program (<$1M annual revenue) |

### 2.3 Fixed Costs

| Cost | Monthly Estimate |
|------|------------------|
| Apple Developer Program | $99/year (~$8.25/mo) |
| OpenRouter API (minimum) | Pay-as-you-go |
| Cloudflare (free tier) | $0 |
| CloudKit (included) | $0 |

---

## 3. Profit Margins by Pack

### 3.1 With 30% Apple Commission

| Pack | Revenue | Apple Cut (30%) | Net Revenue | API Cost (all credits) | Gross Profit | Margin |
|------|---------|-----------------|-------------|------------------------|--------------|--------|
| 10 Credits ($1.99) | $1.99 | $0.60 | $1.39 | $0.40 | **$0.99** | 50% |
| 25 Credits ($3.99) | $3.99 | $1.20 | $2.79 | $1.00 | **$1.79** | 45% |
| 50 Credits ($5.99) | $5.99 | $1.80 | $4.19 | $2.00 | **$2.19** | 37% |

### 3.2 With 15% Apple Commission (Small Business Program)

| Pack | Revenue | Apple Cut (15%) | Net Revenue | API Cost | Gross Profit | Margin |
|------|---------|-----------------|-------------|----------|--------------|--------|
| 10 Credits ($1.99) | $1.99 | $0.30 | $1.69 | $0.40 | **$1.29** | 65% |
| 25 Credits ($3.99) | $3.99 | $0.60 | $3.39 | $1.00 | **$2.39** | 60% |
| 50 Credits ($5.99) | $5.99 | $0.90 | $5.09 | $2.00 | **$3.09** | 52% |

---

## 4. Customer Acquisition Cost (CAC)

### 4.1 Free Credits Cost

Every new user gets 3 free credits. If they use all 3:

| Component | Cost |
|-----------|------|
| 3 API generations | $0.12 |
| **Total CAC (organic)** | **$0.12** |

### 4.2 Paid Acquisition (Hypothetical)

If running paid ads:

| Channel | Estimated CPI (Cost Per Install) |
|---------|----------------------------------|
| Apple Search Ads | $1.50 - $3.00 |
| Meta/Instagram | $1.00 - $2.50 |
| TikTok | $0.80 - $2.00 |

**Total CAC with paid ads = CPI + Free Credits Cost**

| Scenario | CPI | Free Credits | Total CAC |
|----------|-----|--------------|-----------|
| Low cost | $0.80 | $0.12 | **$0.92** |
| Average | $1.50 | $0.12 | **$1.62** |
| High cost | $3.00 | $0.12 | **$3.12** |

---

## 5. Customer Lifetime Value (LTV)

### 5.1 Assumptions

| Metric | Conservative | Moderate | Optimistic |
|--------|--------------|----------|------------|
| Free-to-Paid Conversion | 3% | 5% | 8% |
| Avg. Purchases per Paying User | 2 | 3 | 5 |
| Avg. Pack Size | 10 Credits | 25 Credits | 25 Credits |

### 5.2 LTV Calculation

**Formula:** LTV = (Conversion Rate) × (Purchases per User) × (Avg. Gross Profit per Purchase)

| Scenario | Conversion | Purchases | Gross Profit/Purchase | LTV per User |
|----------|------------|-----------|----------------------|--------------|
| Conservative | 3% | 2 | $0.99 | **$0.06** |
| Moderate | 5% | 3 | $1.79 | **$0.27** |
| Optimistic | 8% | 5 | $1.79 | **$0.72** |

*LTV is calculated per total user (including non-paying)*

### 5.3 LTV per Paying Customer

| Scenario | Purchases | Gross Profit/Purchase | LTV (Paying Only) |
|----------|-----------|----------------------|-------------------|
| Conservative | 2 | $0.99 | **$1.98** |
| Moderate | 3 | $1.79 | **$5.37** |
| Optimistic | 5 | $2.39 | **$11.95** |

---

## 6. LTV:CAC Ratio Analysis

### 6.1 Organic Growth Only (No Paid Ads)

| Scenario | LTV per User | CAC | LTV:CAC Ratio |
|----------|--------------|-----|---------------|
| Conservative | $0.06 | $0.12 | 0.5:1 |
| Moderate | $0.27 | $0.12 | 2.3:1 |
| Optimistic | $0.72 | $0.12 | 6.0:1 |

**Target:** LTV:CAC > 3:1 for sustainable growth

### 6.2 With Paid Acquisition (Avg. $1.62 CAC)

| Scenario | LTV per User | CAC | LTV:CAC Ratio |
|----------|--------------|-----|---------------|
| Conservative | $0.06 | $1.62 | 0.04:1 |
| Moderate | $0.27 | $1.62 | 0.17:1 |
| Optimistic | $0.72 | $1.62 | 0.44:1 |

**Conclusion:** Paid acquisition is NOT viable with current pricing/conversion rates.

---

## 7. Break-Even Analysis

### 7.1 Per-User Break-Even

To recover the $0.12 organic CAC (3 free credits), a user needs to:

| Pack Purchased | Gross Profit | Covers Free Credits? |
|----------------|--------------|---------------------|
| 10 Credits | $0.99 | Yes (8x) |
| 25 Credits | $1.79 | Yes (15x) |
| 50 Credits | $2.19 | Yes (18x) |

**Result:** Just 1 purchase covers the free credits cost many times over.

### 7.2 Monthly Break-Even (Fixed Costs)

| Fixed Cost | Monthly |
|------------|---------|
| Apple Developer | $8.25 |
| **Total Fixed** | **$8.25** |

To cover fixed costs alone:
- Need ~9 purchases of 10-credit pack ($0.99 × 9 = $8.91)
- Or ~5 purchases of 25-credit pack ($1.79 × 5 = $8.95)

---

## 8. Scenario Projections

### 8.1 Monthly Revenue Scenarios

| Users | Conversion | Paying Users | Avg. Order | Revenue | Gross Profit |
|-------|------------|--------------|------------|---------|--------------|
| 1,000 | 5% | 50 | $3.99 | $199.50 | $89.50 |
| 5,000 | 5% | 250 | $3.99 | $997.50 | $447.50 |
| 10,000 | 5% | 500 | $3.99 | $1,995 | $895 |
| 50,000 | 5% | 2,500 | $3.99 | $9,975 | $4,475 |

### 8.2 Annual Projections

| Annual Users | Conversion | Paying | Revenue | Gross Profit | Net (after fixed) |
|--------------|------------|--------|---------|--------------|-------------------|
| 12,000 | 5% | 600 | $2,394 | $1,074 | $975 |
| 60,000 | 5% | 3,000 | $11,970 | $5,370 | $5,271 |
| 120,000 | 5% | 6,000 | $23,940 | $10,740 | $10,641 |

---

## 9. Recommendations

### 9.1 Pricing Optimization

Current pricing is reasonable. Consider testing higher prices:

| Current | Suggested | Rationale |
|---------|-----------|-----------|
| 10 for $1.99 | 10 for $2.99 | Test price elasticity |
| 25 for $3.99 | 25 for $5.99 | Better value perception |
| 50 for $5.99 | 50 for $9.99 | "Best value" anchor |

### 9.2 Reduce Free Credits

| Option | Free Credits | CAC Impact |
|--------|--------------|------------|
| Current | 3 | $0.12 |
| Reduced | 2 | $0.08 |
| Minimal | 1 | $0.04 |

**Trade-off:** Fewer free credits = higher conversion pressure, possibly lower conversion rate.

### 9.3 Improve Conversion

Focus on:
1. **Onboarding quality** - Show value before free credits run out
2. **Push notifications** - Remind users when credits are low
3. **Limited-time offers** - Create urgency for first purchase
4. **Social proof** - Show flyers created by others

### 9.4 Growth Strategy

| Phase | Strategy | CAC | Target LTV:CAC |
|-------|----------|-----|----------------|
| 1 (Launch) | Organic only | $0.045 | >3:1 |
| 2 (Traction) | ASO + organic | $0.10 | >3:1 |
| 3 (Scale) | Selective paid (only if LTV supports) | <$0.50 | >3:1 |

---

## 10. Key Metrics to Track

| Metric | Definition | Target |
|--------|------------|--------|
| CAC | Cost to acquire a user | <$0.15 (organic) |
| LTV | Lifetime value per user | >$0.35 |
| LTV:CAC | Ratio | >3:1 |
| Conversion Rate | Free to paid | >5% |
| ARPU | Avg. revenue per user | >$0.20 |
| ARPPU | Avg. revenue per paying user | >$4.00 |
| Gross Margin | (Revenue - COGS) / Revenue | >45% |

---

## Summary

| Metric | Current State |
|--------|---------------|
| Gross Margin | 37-50% (acceptable) |
| CAC (Organic) | $0.12 (good) |
| CAC (Paid) | Not viable currently |
| LTV:CAC (Organic, Moderate) | 2.3:1 (needs improvement) |
| LTV:CAC (Organic, Optimistic) | 6.0:1 (healthy) |
| Break-even | Very achievable (~5-9 purchases/month) |

**Bottom Line:** FlyGen is profitable on an organic growth basis with acceptable margins. The higher API cost ($0.04/generation) means margins are tighter than typical SaaS, but still viable. Paid acquisition is not recommended until conversion rates exceed 8%. Focus on organic growth, ASO, and conversion optimization to reach the optimistic scenario (6:1 LTV:CAC).
