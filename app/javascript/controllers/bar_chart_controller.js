import { Controller } from "@hotwired/stimulus";
import * as d3 from "d3";

// Connects to data-controller="bar-chart"
export default class extends Controller {
  static targets = ["detail", "detailTitle", "detailIncome", "detailExpense"];
  static values = {
    data: { type: Array, default: [] },
    currencySymbol: { type: String, default: "€" },
  };

  connect() {
    this.resizeObserver = new ResizeObserver(() => this.#draw());
    this.resizeObserver.observe(this.element);
    this.#draw();
  }

  disconnect() {
    this.resizeObserver?.disconnect();
  }

  #draw() {
    const months = this.dataValue || [];
    if (!months.length) return;

    const container = this.element.querySelector("[data-bar-chart-target='canvas']");
    if (!container) return;

    d3.select(container).selectAll("svg").remove();

    const margin = { top: 20, right: 20, bottom: 40, left: 60 };
    const width = container.clientWidth - margin.left - margin.right;
    const height = 360 - margin.top - margin.bottom;

    const svg = d3
      .select(container)
      .append("svg")
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom)
      .append("g")
      .attr("transform", `translate(${margin.left},${margin.top})`);

    const maxTotal = d3.max(months, (m) =>
      Math.max(m.income.total, m.expense.total),
    ) || 1;

    const x0 = d3
      .scaleBand()
      .domain(months.map((m) => m.key))
      .range([0, width])
      .paddingInner(0.3)
      .paddingOuter(0.1);

    const x1 = d3
      .scaleBand()
      .domain(["income", "expense"])
      .range([0, x0.bandwidth()])
      .padding(0.15);

    const y = d3.scaleLinear().domain([0, maxTotal * 1.1]).range([height, 0]);

    const formatValue = (v) =>
      `${this.currencySymbolValue}${d3.format(",.0f")(v)}`;

    // Y axis
    svg
      .append("g")
      .attr("class", "text-secondary")
      .call(
        d3
          .axisLeft(y)
          .ticks(5)
          .tickFormat((d) => formatValue(d)),
      )
      .selectAll("text")
      .attr("class", "text-xs fill-secondary");

    svg.selectAll(".domain, .tick line").attr("stroke", "var(--color-gray-300)");

    // X axis labels
    svg
      .append("g")
      .attr("transform", `translate(0,${height})`)
      .selectAll("text")
      .data(months)
      .join("text")
      .attr("x", (d) => x0(d.key) + x0.bandwidth() / 2)
      .attr("y", 20)
      .attr("text-anchor", "middle")
      .attr("class", "text-xs fill-secondary")
      .text((d) => d.label);

    const self = this;

    months.forEach((month) => {
      ["income", "expense"].forEach((type) => {
        const barX = x0(month.key) + x1(type);
        const barWidth = x1.bandwidth();
        const categories = month[type].categories;
        const total = month[type].total;
        if (total === 0) return;

        const baseColor = type === "income" ? "#10A861" : "#DC2626";

        let cumulative = 0;

        categories.forEach((cat, i) => {
          const segmentTop = total - cumulative - cat.value;
          const segmentBottom = total - cumulative;
          const y1 = y(segmentTop);
          const y2 = y(segmentBottom);
          const segmentHeight = Math.max(y2 - y1, 1);

          const rect = svg
            .append("rect")
            .attr("x", barX)
            .attr("y", y1)
            .attr("width", barWidth)
            .attr("height", segmentHeight)
            .attr("fill", cat.color || baseColor)
            .attr("opacity", type === "income" ? 0.85 : 0.8)
            .attr("cursor", "pointer")
            .on("click", () => self.#showDetail(month));

          rect.append("title").text(`${cat.name}: ${formatValue(cat.value)}`);

          if (i < categories.length - 1) {
            svg
              .append("line")
              .attr("x1", barX)
              .attr("x2", barX + barWidth)
              .attr("y1", y2)
              .attr("y2", y2)
              .attr("stroke", "white")
              .attr("stroke-opacity", 0.4)
              .attr("stroke-width", 1)
              .attr("pointer-events", "none");
          }

          cumulative += cat.value;
        });

        // Bar outline
        svg
          .append("rect")
          .attr("x", barX)
          .attr("y", y(total))
          .attr("width", barWidth)
          .attr("height", height - y(total))
          .attr("fill", "none")
          .attr("stroke", baseColor)
          .attr("stroke-width", 1.5)
          .attr("stroke-opacity", 0.3)
          .attr("rx", 4)
          .attr("pointer-events", "none");
      });
    });

    // Legend
    const legend = d3.select(container).append("div").attr("class", "flex gap-6 justify-center mt-4 text-sm");

    legend
      .append("div")
      .attr("class", "flex items-center gap-2")
      .html(
        '<span class="w-3 h-3 rounded-sm inline-block" style="background:#10A861"></span><span class="text-secondary">Príjmy</span>',
      );

    legend
      .append("div")
      .attr("class", "flex items-center gap-2")
      .html(
        '<span class="w-3 h-3 rounded-sm inline-block" style="background:#DC2626"></span><span class="text-secondary">Výdavky</span>',
      );
  }

  #showDetail(month) {
    if (!this.hasDetailTarget) return;

    this.detailTarget.classList.remove("hidden");
    this.detailTitleTarget.textContent = month.label;

    this.#renderCategoryBreakdown(this.detailIncomeTarget, month.income, "Príjmy");
    this.#renderCategoryBreakdown(this.detailExpenseTarget, month.expense, "Výdavky");
  }

  #renderCategoryBreakdown(container, data, title) {
    const formatValue = (v) =>
      `${this.currencySymbolValue}${d3.format(",.2f")(v)}`;

    let html = `<h4 class="text-sm font-medium text-secondary mb-2">${title}: ${formatValue(data.total)}</h4>`;

    if (data.categories.length) {
      html += '<div class="flex h-2 mb-3 gap-0.5 rounded-full overflow-hidden">';
      data.categories.forEach((cat) => {
        const weight = data.total > 0 ? (cat.value / data.total) * 100 : 0;
        html += `<div class="h-full" style="background-color:${cat.color};width:${weight}%"></div>`;
      });
      html += "</div><div class='flex flex-wrap gap-x-3 gap-y-1 text-xs'>";
      data.categories.forEach((cat) => {
        const weight = data.total > 0 ? Math.round((cat.value / data.total) * 100) : 0;
        html += `<div class="flex items-center gap-1.5">
          <span class="w-2.5 h-2.5 rounded-full shrink-0" style="background-color:${cat.color}"></span>
          <span class="text-secondary">${cat.name}</span>
          <span class="text-primary font-medium">${formatValue(cat.value)} (${weight}%)</span>
        </div>`;
      });
      html += "</div>";
    } else {
      html += '<p class="text-xs text-secondary">Žiadne dáta</p>';
    }

    container.innerHTML = html;
  }
}
