#import "@preview/codly:1.3.0": codly, codly-init, local as codly-local
#import "@preview/codly-languages:0.1.8": codly-languages

#import "./global-constants.typ": (
  indent, leading, underline-offset, underline-thickness,
)

// underline box (can't use #underline(h(1fr)) in v0.12)
#let ubox(..box-args) = box(
  width: 1fr,
  stroke: (bottom: underline-thickness), // Same as underline
  outset: (bottom: underline-offset), // Same as underline
  ..box-args,
)

// Not for export
#let under-text(_text, inside) = {
  set par(spacing: 0.3em)
  box(block(inside) + align(center, text(size: 0.65em, _text)))
}

#let underline-with-text(text-under, text-over, ..box-args) = {
  let underlined-over-text = none
  if text-over == [] {
    underlined-over-text = ubox(..box-args)[~]
  } else {
    underlined-over-text = (
      ubox(..box-args) + underline(text-over) + ubox(..box-args)
    )
  }
  under-text(text-under, underlined-over-text)
}

#let name-placeholder(name, ..box-args) = {
  under-text(
    [(И. О. Фамилия)],
    ubox(..box-args) + underline(name) + ubox(..box-args),
  )
}

#let capitalize(body) = {
  let sequence = [].func()
  let styled = text(red)[].func()
  let text-content = [a].func()
  let text = body
  let first
  let rest
  let process-sequence(body) = {
    let first
    let rest
    first = body.children.at(0)
    if first.func() == text-content {
      first = first.text
      rest = body.children.slice(1)
    }
    sequence(
      (upper(first.clusters().at(0)), first.clusters().slice(1).join()) + rest,
    )
  }
  let process-text(body) = {
    let (first, ..rest) = body.text.clusters()
    upper(first) + rest.join()
  }
  if type(body) == content {
    if body.func() == sequence {
      process-sequence(body)
    } else if body.func() == styled {
      let (child, styles) = (body.child, body.styles)
      if child.func() == sequence {
        styled(process-sequence(child), styles)
      } else {
        styled(process-text(child), styles)
      }
    } else if body.func() == text-content {
      process-text(body)
    } else {
      panic("Unhandled content.func() case")
    }
  } else if type(body) == str {
    (first, ..rest) = body.clusters()
    upper(first) + rest.join()
  } else if type(body) != str {
    panic("body is not content or string")
  }
}

/// Insert current column number. Starts with 1.
///
/// Intended for use in tables that have a ordered number column.
#let column-number = {
  let column-number-counter = counter("column-number")
  column-number-counter.step()
  context column-number-counter.get().first()
}

/// Update/reset the column number. To reset call without the argument.
///
/// Intended for use in tables that have a ordered number column.
#let update-column-number(..value) = {
  let column-number-counter = counter("column-number")
  if value.pos().len() == 0 {
    column-number-counter.update(0)
  } else {
    column-number-counter.update(value.pos().first())
  }
}

// Add description for variables/constants used in a math equation.
#let equation-description(..args) = {
  set par(justify: false)
  let chunks = args.pos().chunks(2)
  let punct = i => if i == chunks.len() - 1 [.] else [;]
  grid(
    // columns: 4,
    columns: 2,
    // align: (auto, right, auto, left),
    row-gutter: leading,
    column-gutter: 0.5em,
    grid.cell(rowspan: chunks.len())[где],
    // ..chunks
    //   .enumerate()
    //   .map(((i, (eq, desc))) => (eq, [---], desc + punct(i)))
    //   .flatten(),
    ..chunks
      .enumerate()
      .map(((i, (eq, desc))) => grid(
        columns: 2,
        [#eq ---] + " ", desc + punct(i),
      ))
      .flatten(),
  )
}

/// Spacing doesn't work the same way as native solution if par leading and
/// spacing are different.
#let correctly-indent-list-and-enum-items(doc) = {
  let first-line-indent() = if type(par.first-line-indent) == dictionary {
    par.first-line-indent.amount
  } else {
    par.first-line-indent
  }

  show list: li => {
    for (i, it) in li.children.enumerate() {
      let nesting = state("list-nesting", 0)
      let indent = context h((nesting.get() + 1) * li.indent)
      let get-nesting() = calc.div-euclid(nesting.get(), 10)
      let marker = context {
        let n = get-nesting()
        if type(li.marker) == array {
          li.marker.at(calc.rem-euclid(n, li.marker.len()))
        } else if type(li.marker) == content {
          li.marker
        } else {
          li.marker(n)
        }
      }
      let parents = state("enum-parents", ()) // Support enum nesting.
      let body = {
        parents.update(arr => arr + (-1,))
        nesting.update(x => x + 10)
        it.body + parbreak()
        nesting.update(x => x - 10)
        parents.update(arr => arr.slice(0, -1))
      }
      let content = {
        marker
        h(li.body-indent)
        body
      }
      context pad(left: int(nesting.get() != 0) * li.indent, content)
    }
  }

  show enum: en => {
    let start = if en.start == auto {
      if en.children.first().has("number") {
        if en.reversed { en.children.first().number } else { 1 }
      } else {
        if en.reversed { en.children.len() } else { 1 }
      }
    } else {
      en.start
    }
    let number = start
    for (i, it) in en.children.enumerate() {
      number = if it.number != auto { it.number } else { number }
      if en.reversed { number = start - i }
      let parents = state("enum-parents", ())
      let get-parents() = parents.get().filter(x => x >= 0)
      let indent = context h((get-parents().len() + 1) * en.indent)
      let num = if en.full {
        context numbering(en.numbering, ..get-parents(), number)
      } else {
        numbering(en.numbering, number)
      }
      let max-num = if en.full {
        context numbering(en.numbering, ..get-parents(), en.children.len())
      } else {
        numbering(en.numbering, en.children.len())
      }
      num = context box(
        width: measure(max-num).width,
        align(right, text(overhang: false, num)),
      )
      let list-nesting = state("list-nesting", 0) // Support list nesting.
      let body = {
        parents.update(arr => arr + (number,))
        list-nesting.update(x => x + 1)
        it.body + parbreak()
        list-nesting.update(x => x - 1)
        parents.update(arr => arr.slice(0, -1))
      }
      if not en.reversed { number += 1 }
      let content = {
        num
        h(en.body-indent)
        body
      }
      context pad(left: int(parents.get().len() != 0) * en.indent, content)
    }
  }
  doc
}

/// You must use next wrapper:
/// ```typ
/// #let code = code-inner.with(read: path => read(path))
/// ```
#let code-inner(
  file,
  read: none,
  attach: true,
  lang: auto,
  title: auto,
  title-full: false,
) = {
  assert(read != none, message: "code-inner: use `read: path => read(path)`")
  let title = if title == auto {
    if title-full { file } else { file.split("/").last() }
  } else { title }
  let header = if title != none {
    align(left, block(width: 100%, stroke: (bottom: 1pt), outset: 0.5em, title))
  }
  codly(header: header)
  let text = read(file)
  if attach { pdf.attach(file, bytes(text)) }
  lang = if lang == auto { file.split(".").last() } else { lang }
  raw(text, lang: lang, block: true)
}

/// You must use next wrapper:
/// ```typ
/// #let fig = fig-inner.with(read: path => read-image(path, encoding: none))
/// ```
#let fig-inner(
  file,
  caption,
  read: none,
  attach: true,
  width: 80%,
  ..image-args,
) = {
  let bytes = read(file)
  figure(
    {
      if attach { pdf.attach(file, bytes) }
      image(bytes, width: width, ..image-args)
    },
    caption: caption,
  )
}
