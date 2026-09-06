#import "@preview/alexandria:0.2.1": *

#import "global-constants.typ": (
  font-size, indent, leading, left-margin, right-margin, underline-offset,
  underline-thickness, y-margin,
)
#import "title-page.typ": title-page
#import "utils.typ": (
  code-inner, codly, codly-init, codly-languages, codly-local, column-number,
  correctly-indent-list-and-enum-items, equation-description, fig-inner,
  update-column-number,
)

#let template(
  year: datetime.today().year(),
  group: "Название группы",
  student-name: "И. И. Иванов",
  professor-name: "А. А. Андреев",
  course-name: "Название дисциплины",
  report-type: "тип работы", // лабораторная | домашняя | практическая | контрольная
  report-number: 0, // number | none
  title: "Название работы",
  faculty: "Название факультета",
  department: "Название кафедры",
  city: "Название города",
  title-image-1: none,
  title-image-2: none,
  read: none,
  doc,
) = {
  // SET SECTION ===============================================================
  set document(author: student-name + " (" + group + ")")
  set page(
    paper: "a4",
    margin: (left: left-margin, right: right-margin, y: y-margin),
    numbering: "1",
  )
  set par(
    justify: true,
    leading: leading,
    spacing: leading,
    first-line-indent: (amount: indent, all: true),
    justification-limits: (tracking: (min: -0.02em, max: 0.02em)),
  )

  set text(
    font: ("Libertinus Serif", "Noto Serif CJK JP", "Noto Color Emoji"),
    size: font-size,
    lang: "ru",
    // hyphenate: false,
  )
  set smartquote(quotes: (single: "„“", double: "«»"))
  set enum(indent: indent)
  set list(indent: indent)
  set terms(indent: indent, hanging-indent: -indent)
  set table(align: (x, y) => if y == 0 { center } else { left } + horizon)
  set underline(stroke: underline-thickness, offset: underline-offset)
  set math.equation(numbering: "(1)", supplement: none)
  // See https://github.com/citation-style-language/styles/pull/7884.
  set bibliography(
    title: "Список использованных источников",
    full: true,
    style: "gost-r-7-0-5-2008-numeric.csl",
  )
  set pagebreak(weak: true)
  set rotate(reflow: true)
  set scale(reflow: true)
  set skew(reflow: true)

  // SHOW SECTION ==============================================================
  show heading: set text(font-size)
  show heading: set align(center)

  show outline: it => it + pagebreak()
  show bibliography: it => pagebreak() + it

  // Make it par-like.
  show: correctly-indent-list-and-enum-items

  show: codly-init
  show raw: set text(font: (
    "Fira Code",
    "Noto Sans Mono CJK JP",
    "Noto Color Emoji",
  ))
  // 80 line width for use with Codly
  show raw.where(block: true): set text(size: font-size * 0.64)
  show raw.where(block: false): set text(size: font-size * 0.75)
  show raw: it => {
    show emph: set text(font: "Fira Mono")
    show strong: set text(font: "Fira Mono")
    it
  }
  codly(
    number-align: right,
    stroke: 1pt + black,
    lang-inset: 0.3em,
    lang-outset: (x: 0.38em, y: 0.01em),
    languages: codly-languages,
  )

  // Preserve equation numbering in references.
  show ref: it => {
    if it.element == none or it.element.func() != math.equation { return it }
    let eq = it.element
    let num = numbering(eq.numbering, ..counter(eq.func()).at(eq.location()))
    let supplement = (if it.supplement == auto { eq } else { it }).supplement
    if supplement not in (text(""), [], none) { supplement += [~] }
    link(eq.location())[#supplement#num]
  }

  // References to floating figures point to wrong location
  // https://github.com/typst/typst/issues/4359#issuecomment-3564926925
  show figure: it => {
    if it.placement == none { return it }

    // Re-wrap placed figures to include metadata containing
    // the body's location.
    place(it.placement, float: true, scope: it.scope, {
      let fields = it.fields()
      let body = fields.remove("body")
      if "label" in fields { _ = fields.remove("label") }
      let counter = fields.remove("counter")

      // Need to step back to keep the same number in the new figure.
      counter.update(n => n - 1)

      let meta = context metadata((
        figure-location: it.location(),
        body-location: here(),
      ))

      if it.kind == table {
        layout(size => {
          let width = measure(it.body, ..size).width
          show: block.with(width: width, breakable: true)
          show: align.with(left)
          block(sticky: true, breakable: false, it.caption)
          meta + body
        })
      } else {
        show: block.with(width: 100%)
        figure(meta + body, ..fields, placement: none)
      }
    })
  }
  show ref: it => {
    let fig = it.element
    if fig == none { return it }
    if fig.func() != figure { return it }
    if fig.numbering == none { return it }
    if fig.placement == none { return it }

    // Rebuild reference from scratch.
    let num = numbering(fig.numbering, ..fig.counter.at(fig.location()))
    // panic(it.supplement)
    // panic(fig.supplement)
    let supplement = (if it.supplement == auto { fig } else { it }).supplement
    if supplement not in (text(""), [], none) { supplement += [~] }

    // Use location of figure's body for linking.
    let location = query(metadata)
      .find(data => (
        type(data.value) == dictionary
          and data.value.at("figure-location", default: none) == fig.location()
      ))
      .value
      .body-location

    link(location, [#supplement#num])
  }

  let in-ref = state("in-ref", false)
  show ref: it => in-ref.update(true) + it + in-ref.update(false)
  let sup(fig, ref) = (supplement: context if in-ref.get() [#ref] else [#fig])
  set figure(placement: auto)
  show figure: set par(leading: 1em - 0.75em)
  show figure.where(kind: image): set figure(..sup("Рис.", "рис."))
  show figure.where(kind: table): set figure(..sup("Таблица", "табл."))
  // show figure.where(kind: raw): set figure(..sup("Листинг", "лист."))

  show table.cell.where(y: 0): strong
  show table: set par(justify: false)
  show figure: set par(justify: false, leading: 0.5em)
  show figure.caption: set par(justify: false)
  show figure.where(kind: table): set figure.caption(
    position: top,
    separator: [ --- ],
  )
  show figure.where(kind: table): set block(breakable: true)
  show figure.where(kind: table): it => {
    show figure.caption: set align(left)
    it
  }

  // Merged into previous `show figure`.
  // show figure.where(kind: table): fig => layout(size => {
  //   let width = measure(fig.body, ..size).width
  //   show: block.with(width: width, breakable: true)
  //   show: align.with(left)
  //   block(sticky: true, breakable: false, fig.caption)
  //   fig.body
  // })

  show: alexandria(prefix: "x-", read: {
    if read == none { std.read } else { read }
  })
  state("__report-read").update(x => read)

  title-page(
    year: year,
    group: group,
    student-name: student-name,
    professor-name: professor-name,
    course-name: course-name,
    report-type: report-type,
    report-number: report-number,
    title: title,
    faculty: faculty,
    department: department,
    city: city,
    title-image-1: title-image-1,
    title-image-2: title-image-2,
  )
  pagebreak()

  doc
}

#let flipped-page = page.with(
  margin: (top: left-margin, bottom: right-margin, x: y-margin),
  flipped: true,
)

/// A bibliography / reference listing.
///
/// You can create a new bibliography by calling this function with a path to a
/// bibliography file in either one of two formats:
///
/// - A Hayagriva `.yaml`/`.yml` file. Hayagriva is a new bibliography
///   file format designed for use with Typst. Visit its
///   #link("https://github.com/typst/hayagriva/blob/main/docs/file-format.md")[documentation]
///   for more details.
/// - A BibLaTeX `.bib` file.
///
/// As soon as you add a bibliography somewhere in your document, you can start
/// citing things with reference syntax (`@key`) or explicit calls to the
/// #link("https://typst.app/docs/reference/model/cite/")[citation] function
/// (`#cite(<key>)`). The bibliography will only / show entries for works that
/// were referenced in the document.
///
/// = Styles
/// Typst offers a wide selection of built-in
/// #link("https://typst.app/docs/reference/model/bibliography/#parameters-style")[citation and bibliography styles].
/// Beyond those, you can add and use custom
/// #link("https://citationstyles.org/")[CSL] (Citation Style Language) files.
/// Wondering which style to use? Here are some good defaults / based on what
/// discipline you're working in:
///
/// #table(
///   columns: 2,
///   table.header([Fields], [Typical Styles]),
///   [Engineering, IT], `"ieee"`,
///   [Psychology, Life Sciences], `"apa"`,
///   [Social sciences], `"chicago-author-date"`,
///   [Humanities], [`"mla"`, `"chicago-notes"`, `"harvard-cite-them-right"`],
///   [Economics], `"harvard-cite-them-right"`,
///   [Physics], `"american-physics-society"`,
/// )
///
/// = Example
/// ```typ
/// This was already noted by
/// pirates long ago. @arrgh
///
/// Multiple sources say ...
/// @arrgh @netwok.
///
/// #bibliography("works.bib")
/// ```
/// ────────────────────────────────────────────────────────────────────────────
///
/// #link("https://typst.app/docs/reference/model/bibliography/")[Open docs]
///
/// - sources (str, bytes, array): One or multiple paths to or raw bytes for
///   Hayagriva `.yaml` and/or BibLaTeX `.bib` files.
///
///   This can be a:
///   - A path string to load a bibliography file from the given path. For
///     more details about paths, see the
///     #link("https://typst.app/docs/reference/syntax/#paths")[Paths section].
///   - Raw bytes from which the bibliography should be decoded.
///   - An array where each item is one of the above.
/// - title (none, auto, content): The title of the bibliography.
///
///   - When set to `auto`, an appropriate title for the
///     #link("https://typst.app/docs/reference/text/text/#parameters-lang")[text language]
///     will be used. This is the default.
///   - When set to `none`, the bibliography will not have a title.
///   - A custom title can be set by passing content.
///
///   The bibliography's heading will not be numbered by default, but you can
///   force it to be with a show-set rule:
///   `show bibliography: set heading(numbering: "1.")`
/// - full (bool): Whether to include all works from the given
///   bibliography files, even those that weren't cited in the document.
///
///   To selectively add individual cited works without showing them, you can
///   also use the `cite` function with
///   #link("https://typst.app/docs/reference/model/cite/#parameters-form")[`form`]
///   set to `none`.
/// - style (str, bytes): The bibliography style.
///
///   This can be:
///   - A string with the name of one of the built-in styles (see below). Some
///     of the styles listed below appear twice, once with their full name and
///     once with a short alias.
///   - A path string to a #link("https://citationstyles.org/")[CSL file]. For
///     more details about paths, see the
///     #link("https://typst.app/docs/reference/syntax/#paths")[Paths section].
///   - Raw bytes from which a CSL style should be decoded.
#let bibliography(sources, full: auto, style: auto, title: auto) = context {
  let read = state("__report-read").get()
  assert(
    read != none,
    message: "Apply template with `read: path => read(path)` argument",
  )
  let full = if full == auto { std.bibliography.full } else { full }
  let style = if style == auto { std.bibliography.style } else { style }
  let title = if title == auto { std.bibliography.title } else { title }
  let sources = sources
  show std.bibliography: none
  if type(sources) != array { sources = (sources,) }
  load-bibliography(
    sources,
    full: full,
    style: if "." in style { bytes(std.read(style)) } else { style },
  )
  pagebreak()
  sources.map(path => pdf.attach("/" + path, bytes(read(path)))).join()
  sources = sources.map(read).map(bytes)
  std.bibliography(sources, full: full, style: style, title: title)
  context {
    heading(numbering: none, title)
    let (references, ..rest) = get-bibliography("x-")
    let bib = (references: references, ..rest)
    let gutter = v(par.spacing, weak: true)
    for (i, e) in bib.references.enumerate() {
      if i != 0 { gutter }
      if e.prefix != none { hayagriva.render(e.prefix) + [~] }
      [#metadata(none)#label(bib.prefix + e.key)]
      hayagriva.render(e.reference)
    }
  }
}
