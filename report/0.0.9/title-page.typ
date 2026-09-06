#import "global-constants.typ": left-margin, top-margin
#import "utils.typ": capitalize, name-placeholder, ubox, underline-with-text

/// - year (int, content):,
/// - group (str):
/// - student-name (str):
/// - professor-name (str, content):
/// - course-name (str, content):
/// - report-type (str, content):
/// - report-number (int, float, none):
/// - title (str, content, none):
/// - faculty (str, content):
/// - department (str, content):
/// - city (str, content):
/// - title-image-1 (none, content):
/// - title-image-2 (none, content):
#let title-page(
  year: datetime.today().year(),
  group: "Название группы",
  student-name: "И. И. Иванов",
  professor-name: "А. А. Андреев",
  course-name: "Название дисциплины",
  report-type: "тип работы", // лабораторная | домашняя | практическая | контрольная
  report-number: 0, // number | none
  title: "Название работы", // string | content | none
  faculty: "Название факультета",
  department: "Название кафедры",
  city: "Название города",
  title-image-1: none,
  title-image-2: none,
) = {
  for name in (student-name, professor-name) {
    let first-part = name.split().first()
    assert(first-part.clusters().len() == 2, message: "surname goes last")
  }

  set page(numbering: none)

  { // Top part with coat of arms
    set text(size: 0.74em)
    set par(leading: 0.6em)
    grid(
      columns: (9.0em, auto),
      gutter: 1.5em,
      align: center + horizon,
      inset: (top: 0pt, right: 0pt, rest: 0.5em),
      image("./bmstu-coat-of-arms.svg"),
      strong[
        Министерство науки и высшего образования Российской Федерации \
        Калужский филиал федерального государственного автономного \
        образовательного учреждения высшего образования \
        "Московский государственный технический университет \
        имени Н. Э. Баумана \
        (национальный исследовательский университет)" \
        (КФ МГТУ им. Н. Э. Баумана)
      ],
    )
  }

  // Thick line
  {
    set block(below: 3pt, above: 0pt)
    line(length: 100%, stroke: 3pt)
    line(length: 100%, stroke: 1pt)
  }

  v(1fr)

  { // Faculty and department
    // show par: it => [*#it*]
    // show par: strong
    let faculty-key = "Факультет"
    let department-key = "Кафедра"

    for (key, value) in (faculty-key, department-key).zip((faculty, department)) {
      block({
        key + " " + ubox(width: 1em)
        // underline(emph(value))
        underline(value)
        ubox(width: 1em)
      })
      v(0.5em)
    }
  }

  v(1fr)

  { // Report titles
    // set text(size: 1.3em)
    set align(center)
    set par(justify: false)
    show: strong
    let number = [#sym.numero #report-number]
    if report-number == none { number = none }
    let type-and-number = text(size: 1.3em, if report-type in (
      "лабораторная",
      "домашняя",
      "практическая",
      "контрольная",
    ) {
      capitalize[#report-type работа #number]
    } else {
      capitalize[#report-type #number]
    })
    strong[#type-and-number]
    if title != none { block(spacing: 1.6em)["_#(title)_"] }
    block(spacing: 1.6em)[по дисциплине: "_#(course-name)_"]
    context {
      set document(
        title: if document.title == none [#course-name. #type-and-number]
      )
    }
  }

  v(1fr)

  context { // Names and signatures
    let signature = underline-with-text[(Подпись)][]
    let student-length = measure(student-name).width
    let professor-length = measure(professor-name).width
    let longest-name = calc.max(student-length, professor-length)

    grid(
      columns: (2fr, 6.5em, longest-name + 2em),
      column-gutter: (1em, 0.5em),
      row-gutter: 3em,
      [Выполнил: студент группы #group], signature, name-placeholder(student-name),
      [Проверил:],                    signature, name-placeholder(professor-name),
    )
  }

  v(1fr)

  grid(
    gutter: 1.5em,
    [Дата сдачи (защиты):],
    [Результаты сдачи (защиты):],
  )

  v(1em)

  align(center, grid(
    align: left,
    gutter: 1em,
    [-- Балльная оценка:],
    [-- Оценка:],
  ))

  v(1fr)

  // City and year
  align(center)[#city, #year]

  for title-image in (title-image-1, title-image-2) {
    if title-image != none {
      let x = title-image.x - left-margin
      let y = title-image.y - top-margin
      place(top + left, dx: x, dy: y, title-image.image)
    }
  }
}
