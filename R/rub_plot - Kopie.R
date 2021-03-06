#' Plot RUB figure
#'
#' @param df Data Frame bzw. Tibble
#'
#' @return ggplot object
#' @export
#'
#' @examples
#' \dontrun{
#' plot_figure(df)
#' }
plot_figure <- function(df) {
  figure_type_id <- unique(df[["figure_type_id"]])

  if (length(figure_type_id) == 1) {
    if (figure_type_id == 1) {
      p <- df %>%
        rub_plot_type_1(
          x_var = x,
          y_var = y,
          y_axis_label = .[[1, "y_label"]],
          fill_var = fill,
          fill_label = fill_label,
          caption = .[[1, "source_caption"]]
        )
    } else if (figure_type_id == 2) {
      p <- df %>%
        rub_plot_type_2(
          x_var = x,
          y_var = y,
          fill_var = fill,
          fill_label = fill_label,
          fill_reverse = .[[1, "fill_reverse"]],
          facet_var = facet,
          caption = .[[1, "source_caption"]]
        )
    } else if (figure_type_id == 3) {
      p <- df %>%
        rub_plot_type_3(
          x_var = x,
          y_var = y,
          fill_var = fill,
          fill_label = fill_label,
          fill_reverse = .[[1, "fill_reverse"]],
          facet_var = facet,
#          group = group,
          caption = .[[1, "source_caption"]]
        )
    }
  } else if (length(figure_type_id) > 1) {
    if (identical(figure_type_id, c(1L, 4L)) |
        identical(figure_type_id, c(4L, 1L))) {
      p <- rub_plot_type_1_and_4(df)
    }
  }

  return(p)
}

#' Get discrete palette for the plot
#'
#' At the moment, RUB_palettes has discrete palettes for up to eight unique
#'     colors. Above that number, colors are interpolated.
#'
#' @param colors_n Integer for the number of requestes colors in the discrete
#'     palette.
#'
#' @return Name of the appropriate discrete palette from RUB_palettes
#'
#' @examples
#' plot_discrete_palette(12)
plot_discrete_palette <- function(colors_n)  {
  palette <- paste0(
    "discrete_",
    pmin(
      colors_n,
      8L
      )
    )

  if(colors_n > 8)  {
    warning("Number of requested colors for discrete palette exceeds eight.
            No predefined palette for more than eight discrete colors exists
            in RUB_palettes. Additional colors will be interpolated.")
  }

  return(palette)
}

#' Plot vertical stacked bar chart (figure type 1)
#'
#' vertical stacked bar chart in the RUB corporate design. The variables x_var,
#' y_var and fill_var are required, all others are optional.
#'
#' @param df Data frame
#' @param x_var Required variable name for the variable containing the discrete
#'     x-coordinates.
#' @param y_var Required variable name for the variable containing the
#'     continuous y-coordinates.
#' @param y_axis_label Optional label for the y-axis, defaults to an empty
#'     string.
#' @param fill_var Variable name for the discrete variable which determines the
#'     groups to be stacked, e.g. degree.
#' @param fill_reverse Boolean indicating whether the order of the fill variable
#'     should be reversed, default = FALSE.
#' @param fill_label Optional variable name for the character variable
#'     containing the names of the fill variable, defaults to NULL.
#' @param caption Optional character containing the data source for the figure
#'     (prefix 'Quelle:' is automatically added).
#' @param caption_prefix Optional character containing the prefix for the
#'     caption, defaults to 'Quelle:'.
#' @param filter_cutoff Optional cutoff value for the suppression of data
#'     labels. By default, all values below 0.04 of the total value of the
#'     stacked bar chart are suppressed.
#' @param facet_var Optional variable name for the discrete variable to facet
#'     by, defaults to NULL.
#' @inheritParams theme_rub
#'
#' @return A ggplot object
#' @export
#' @importFrom rlang .data
#'
#' @examples
#' # Create test values for all three mandatory variables (x_var, y_var,
#' # fill_var).
#' df_t1_ex1 <- tibble::tribble(
#'    ~term, ~students, ~degree,
#'    "Spring '13", 120, "Bachelor 1-Subject",
#'    "Spring '14", 105, "Bachelor 1-Subject",
#'    "Spring '15", 124, "Bachelor 1-Subject",
#'    "Spring '16", 114, "Bachelor 1-Subject",
#'    "Spring '17", 122, "Bachelor 1-Subject",
#'    "Spring '13", 121, "Master 1-Subject",
#'    "Spring '14", 129, "Master 1-Subject",
#'    "Spring '15", 122, "Master 1-Subject",
#'    "Spring '16", 168, "Master 1-Subject",
#'    "Spring '17", 7, "Master 1-Subject",
#' )
#'
#' # The data source is df_t1_ex1, x_var is mapped to term, y_var to students,
#' # and the fill_var to degree.
#' rub_plot_typ_1(
#'    df = df_t1_ex1,
#'    x_var = term,
#'    y_var = students,
#'    fill_var = degree
#' )
rub_plot_type_1 <- function(df, x_var,
                           y_var, y_axis_label = "",
                           fill_var, fill_reverse = FALSE,
                           fill_label = NULL,
                           caption = "", caption_prefix = "Quelle:",
                           filter_cutoff = 0.04, facet_var = NULL,
                           color = RUB_colors["blue"], base_family = "RubFlama",
                           base_size = 11) {
  # Defuse R expressions
  fill_var_sym <- rlang::ensym(fill_var)
  y_var_quo <-  rlang::enquo(y_var)
  facet_var <- rlang::enquo(facet_var)

  # Booleans
  has_y_axis_label <- y_axis_label != ""
  has_facet <- !rlang::quo_is_null(facet_var)

  # Determine required number of discrete colors and get appropriate palette
  colors_n <- dplyr::n_distinct(df[[fill_var_sym]])
  palette <- plot_discrete_palette(
    colors_n = colors_n
    )

  # This function makes sure that the fill variable is plotted in the correct
  # order and with the appropriate labels.
  df <- set_factor_var(
    df = df,
    var = {{fill_var}},
    var_label = {{fill_label}},
    reverse = fill_reverse
    )

  fill_levels <- levels(df[[fill_var_sym]])

  caption <- ifelse(
    caption[1] == "",
    "",
    paste(
      caption_prefix,
      caption[1]
      )
    )
  # Get data frame containing position and values for (filtered) value labels.
  # The y-position of the data labels is contained in the label_var.
  df_label <- add_label_position(
    df,
    x_var = {{x_var}},
    y_var = {{y_var}},
    fill_var = {{fill_var}},
    facet_var = {{facet_var}},
    filter_cutoff = filter_cutoff,
    is_percentage = FALSE
  )

  label_var <- paste0(
    "label_",
    rlang::as_label(
      y_var_quo
    )
  )

  # Set facet element
  if(!has_facet)  {
    facet <- NULL
  } else {
    facet <- ggplot2::facet_wrap(
      ggplot2::vars(
          !!facet_var
        ),
      ncol = 1,
      scales = "free_y"
      )
  }

  # Plotting function
  ggplot2::ggplot(
      mapping = ggplot2::aes(
      x = {{x_var}},
      y = {{y_var}},
      fill = {{fill_var}}
    )
  ) +
    ggplot2::geom_bar(
      data = df,
      stat = "identity",
      width = 0.55
    ) +
    ggplot2::geom_label(
      data = df_label,
      ggplot2::aes(
        x = {{x_var}},
        y = .data[[label_var]],
        fill = {{fill_var}},
        label = {{y_var}}
      ),
      size = base_size / 5,
      family = base_family,
      color = color,
      fill = "white",
      show.legend = FALSE,
      label.r = ggplot2::unit(0, "lines"),
      label.padding = ggplot2::unit(0.10, "lines")
    ) +
    facet +
    ggplot2::scale_y_continuous(
      expand = c(0, 0),
      labels = scales::label_number(
        big.mark = ".",
        decimal.mark = ","
      )
    ) +
    scale_fill_rub(
      palette = palette,
      discrete = TRUE,
      name = NULL,
      label = fill_levels,
      colors_n
    ) +
    ggplot2::guides(
      fill = ggplot2::guide_legend(
        reverse = FALSE,
        byrow = TRUE
      )
    ) +
    ggplot2::labs(
      y = y_axis_label[1],
      caption = caption
      ) +
    theme_rub(
      base_family = base_family,
      base_size = base_size,
      color = color,
      has_facet = has_facet,
      y_axis_label = has_y_axis_label
      )
}

#' Plot vertical stacked bar charts that are scaled to 100\% (figure type 2)
#'
#' @inheritParams rub_plot_type_1
#' @inheritParams theme_rub
#'
#' @return A ggplot object
#' @export
#' @importFrom rlang .data
#'
#' @examples
#' # Create test values for all three mandatory variables (x_var, y_var, fill_var)
#' df_t2_ex1 <- tibble::tribble(
#'   ~cohort_term, ~status_percentage, ~cohort_status,
#'   "2. cohort term", 0.9513551740, "Studying",
#'   "2. cohort term", 0.0029748098, "Changed subject",
#'   "2. cohort term", 0.0004673679, "Graduated",
#'   "2. cohort term", 0.0186648938, "Disenrolled without degree",
#'   "2. cohort term", 0.0265377545, "Dropped subject",
#'   "4. cohort term", 0.8896149868, "Studying",
#'   "4. cohort term", 0.0616919929, "Changed subject",
#'   "4. cohort term", 0.0016484686, "Graduated",
#'   "4. cohort term", 0.0201024499, "Disenrolled without degree",
#'   "4. cohort term", 0.0269421019, "Dropped subject",
#'   "6. cohort term", 0.7901183540, "Studying",
#'   "6. cohort term", 0.1502641318, "Changed subject",
#'   "6. cohort term", 0.0074548056, "Graduated",
#'   "6. cohort term", 0.0243490259, "Disenrolled without degree",
#'   "6. cohort term", 0.0278136827, "Dropped subject",
#'   "8. cohort term", 0.6115873010, "Studying",
#'   "8. cohort term", 0.2961468339, "Changed subject",
#'   "8. cohort term", 0.0104080044, "Graduated",
#'   "8. cohort term", 0.0274549015, "Disenrolled without degree",
#'   "8. cohort term", 0.0544029593, "Dropped subject",
#' )
#'
#' rub_plot_type_2(
#'   df = df_t2_ex1,
#'   x_var = cohort_term,
#'   y_var = status_percentage,
#'   fill_var = cohort_status
#' )
rub_plot_type_2 <- function(df, x_var,
                           y_var, y_axis_label = "",
                           fill_var, fill_label = NULL,
                           fill_reverse = FALSE,
                           facet_var = NULL, caption = "",
                           caption_prefix = "Quelle:", filter_cutoff = 0.04,
                           color = RUB_colors["blue"], base_family = "RubFlama",
                           base_size = 11) {

  # Defuse R expressions
  fill_var_sym <- rlang::ensym(fill_var)
  y_var_quo <- rlang::enquo(y_var)
  facet_var <- rlang::enquo(facet_var)

  # Booleans
  has_y_axis_label <- y_axis_label != ""
  has_facet <- !rlang::quo_is_null(facet_var)

  # Determine required number of discrete colors and get appropriate palette
  colors_n <- dplyr::n_distinct(df[[fill_var_sym]])
  palette <- plot_discrete_palette(
    colors_n = colors_n
  )

  # Make sure that the fill variable is plotted in the correct order and with
  # the appropriate labels.
  df <- set_factor_var(
    df = df,
    var = {{fill_var}},
    var_label = {{fill_label}},
    reverse = fill_reverse
  )

  fill_levels <- levels(df[[fill_var_sym]])

  caption <- ifelse(
    caption[1] == "",
    "",
    paste(
      caption_prefix,
      caption[1]
    )
  )

  # Get data frame containing position and values for (filtered) value labels.
  # The y-position of the data labels is contained in the label_var.
  df_label <- add_label_position(
    df,
    x_var = {{x_var}},
    y_var = {{y_var}},
    fill_var = {{fill_var}},
    facet_var = {{facet_var}},
    filter_cutoff = filter_cutoff,
    is_percentage = TRUE
  )

  label_var <- paste0(
    "label_",
    rlang::as_label(
      y_var_quo
    )
  )

  # Set facet element
  if(!has_facet)  {
    facet <- NULL
  } else {
    facet <- ggplot2::facet_wrap(
      ggplot2::vars(
        !!facet_var
      ),
      ncol = 1,
      scales = "free_y"
    )
  }

  # Plotting function
  ggplot2::ggplot() +
    ggplot2::geom_bar(
      data = df,
      ggplot2::aes(
        x = {{x_var}},
        y = {{y_var}},
        fill = {{fill_var}}
      ),
      position = "fill",
      stat = "identity",
      width = 0.55
    ) +
    ggplot2::geom_label(
      data = df_label,
      ggplot2::aes(
        x = {{x_var}},
        y = .data[[label_var]],
        group = {{fill_var}},
        # https://community.rstudio.com/t/using-label-percent-with-the-label-argument-of-geom-text-and-geom-label/54244/2
        label = scales::label_percent(
          accuracy = 1L
        )({{y_var}})
      ),
      size = base_size / 5,
      family = base_family,
      color = color,
      fill = "white",
      show.legend = FALSE,
      label.r = ggplot2::unit(0, "lines"),
      label.padding = ggplot2::unit(0.10, "lines")
    ) +
    facet +
    ggplot2::scale_y_continuous(
      expand = c(0, 0),
      label = scales::percent
    ) +
    scale_fill_rub(
      palette = palette,
      discrete = TRUE,
      name = NULL,
      label = fill_levels,
      colors_n
    ) +
    ggplot2::guides(
      fill = ggplot2::guide_legend(
        reverse = FALSE,
        byrow = TRUE
      )
    ) +
    ggplot2::labs(
      y = y_axis_label[1],
      caption = caption
    ) +
    theme_rub(
      base_family = base_family,
      base_size = base_size,
      color = color,
      has_facet = has_facet,
      y_axis_label = has_y_axis_label
    )
}

#' Plot horizontal stacked bar charts that are scaled to 100\% (figure type 3)
#'
#' @param x_axis_label Optional label for the x-axis, defaults to an empty
#'     string.
#' @param legend_reverse Optional boolean indicating whether the legend should
#'     be reverted, defaults to fill_reverse.
#' @inheritParams rub_plot_type_1
#' @inheritParams theme_rub
#'
#' @return A ggplot object
#' @export
#' @importFrom rlang .data
#' @examples
#' # Create test values for all three mandatory variables (x_var, y_var,
#' # fill_var)
#' df_t3_ex1 <- tibble::tribble(
#'    ~survey_group, ~item_value, ~item_value_percentage,
#'    "Bachelor 1-Subject (n=400)", "Exceeded prescribed period of study", 0.30,
#'    "Bachelor 1-Subject (n=400)", "Within prescribed period of study", 0.70,
#'    "SG Bachelor 1-Subject (n=669)", "Exceeded prescribed period of study", 0.11,
#'    "SG Bachelor 1-Subject (n=669)", "Within prescribed period of study", 0.89
#' )
#'
#' rub_plot_type_3(
#'    df = df_t3_ex1,
#'    x_var = item_value_percentage,
#'    y_var = survey_group,
#'    fill_var = item_value,
#' )
rub_plot_type_3 <- function(df, x_var,
                           y_var, x_axis_label = "",
                           fill_var, fill_label = NULL,
                           fill_reverse = FALSE, legend_reverse = FALSE,
                           facet_var = NULL, caption = "",
                           caption_prefix = "Quelle:", filter_cutoff = 0.04,
                           color = RUB_colors["blue"], base_family = "RubFlama",
                           base_size = 11) {

  # Using ggplot2::coord_flip() effectively switches the x- and y-axis. This is
  # confusing to the user, because what is displayed as x-axis are actually the
  # y-values and vice versa. To enhance the user experience, this function
  # switches x and y internally.

  # Defuse R expressions
  y_var_sym <- rlang::ensym(y_var)
  fill_var_sym <- rlang::ensym(fill_var)
  x_var_quo <- rlang::enquo(x_var)
  facet_var <- rlang::enquo(facet_var)

  # Booleans
  has_x_axis_label <- x_axis_label != ""
  has_facet <- !rlang::quo_is_null(facet_var)

  # Determine required number of discrete colors and get appropriate palette
  colors_n <- dplyr::n_distinct(df[[fill_var_sym]])
  palette <- plot_discrete_palette(
    colors_n = colors_n
  )

  # y variable is turned into a factor before plotting to preserve ordering.
  # Order of y variable always needs to be reverted for this plot type.
  is_factor_y <- is.factor(df[[y_var_sym]])
  if(!is_factor_y) {
    df[[y_var_sym]] <- factor(df[[y_var_sym]], levels = unique(df[[y_var_sym]]))
    df[[y_var_sym]] <- forcats::fct_rev(df[[y_var_sym]])
  }

  # Make sure that the fill variable is plotted in the correct order and with
  # the appropriate labels.
  df <- set_factor_var(
    df = df,
    var = {{fill_var}},
    var_label = {{fill_label}},
    reverse = !fill_reverse,
    figure_type_id = 3L
  )

  fill_levels <- levels(df[[fill_var_sym]])

  caption <- ifelse(
    caption[1] == "",
    "",
    paste(
      caption_prefix,
      caption[1]
      )
    )

  # Get data frame containing position and values for (filtered) value labels.
  # The y-position of the data labels is contained in the label_var.
  df_label <- add_label_position(
    df,
    x_var = {{y_var}},
    y_var = {{x_var}},
    fill_var = {{fill_var}},
    facet_var = {{facet_var}},
    filter_cutoff = filter_cutoff,
    is_percentage = TRUE
  )

  label_var <- paste0(
    "label_",
    rlang::as_label(
      x_var_quo
    )
  )

  # Set facet element
  if(!has_facet)  {
    facet <- NULL
  } else {
    facet <- ggforce::facet_col(
      ggplot2::vars(
        !!facet_var
      ),
      scales = "free_y",
      space = "free"
    )
  }

  # Plotting function
  ggplot2::ggplot(
    data = df,
    ggplot2::aes(
      x = {{y_var}},
      y = {{x_var}},
      fill = {{fill_var}}
    )
  ) +
    ggplot2::geom_bar(
      position = "fill",
      stat = "identity"
      ) +
    ggplot2::geom_label(
      data = df_label,
      ggplot2::aes(
        label = sprintf(
          "%1.0f%%",
          {{x_var}} * 100
          ),
        y = .data[[label_var]],
        group = {{fill_var}}
      ),
      size = base_size / 5,
      family = base_family,
      colour = color,
      fill = "white",
      show.legend = FALSE,
      label.r = ggplot2::unit(0, "lines"),
      label.padding = ggplot2::unit(0.10, "lines")
    ) +
    facet +
    scale_fill_rub(
      palette = palette,
      discrete = TRUE,
      name = NULL,
      label = fill_levels,
      colors_n
    ) +
    ggplot2::scale_x_discrete(
      expand = c(0, 0)
      ) +
    ggplot2::scale_y_continuous(
      label = scales::percent,
      expand = ggplot2::expansion(
        mult = c(0, .025)
        )
      ) +
    ggplot2::guides(
      fill = ggplot2::guide_legend(
        reverse = !legend_reverse,
        byrow = TRUE
      )
    ) +
    ggplot2::labs(
      caption = caption,
      y = x_axis_label[1]
    ) +
    ggplot2::coord_flip() +
    theme_rub(
      base_family = base_family,
      base_size = base_size,
      color = color,
      has_facet = has_facet,
      x_axis_label = has_x_axis_label
    ) +
    ggplot2::theme(
      axis.ticks.y = ggplot2::element_blank(),
      axis.line.y = ggplot2::element_blank()
    )
}

#' Plot grouped line chart (figure type 4)
#'
#' @inheritParams rub_plot_type_1
#' @inheritParams rub_plot_type_3
#' @param group_var Variable name for the discrete variable which determines the
#'     groups forming one line, e.g. degree_id.
#' @param group_label Optional variable name for the character variable
#'     containing the names of the group variable (e.g. degree_txt), defaults to #'     NULL.
#' @param filter_cutoff Optional integer marking the cutoff below which all
#'     value labels are suppressed, defaults to 5.
#' @inheritParams theme_rub
#'
#' @return Ein ggplot Objekt
#' @export
#' @importFrom rlang .data
#'
#' @examples
#' \dontrun{
#' rub_plot_type_4(
#'    df = df_fig_t4,
#'    x = time,
#'    y = value_n_total,
#'    group = degree_sort,
#'    group_label = degree_txt
#' )
#' }
rub_plot_type_4 <- function(df, x_var, x_axis_label = "",
                           y_var, y_axis_label = "",
                           group_var, group_label = NULL,
                           caption = "", caption_prefix = "Quelle:",
                           filter_cutoff = 5, facet_var = NULL,
                           color = RUB_colors["blue"], base_family = "RubFlama",
                           base_size = 11) {

  # Defuse R expressions
  y_var_sym <- rlang::ensym(y_var)
  group_var_sym <- rlang::ensym(group_var)
  facet_var_quo <- rlang::enquo(facet_var)
  group_label_quo <- rlang::enquo(group_label)

  # Booleans
  has_x_axis_label <- x_axis_label != ""
  has_y_axis_label <- y_axis_label != ""
  has_facet <- !rlang::quo_is_null(facet_var_quo)
  has_group_label <- !rlang::quo_is_null(group_label_quo)

  if(has_group_label) {
    group_label_sym <- rlang::ensym(group_label)
  } else  {
    group_label_sym <- rlang::ensym(group_var)
    }

  # Plotting variables
  group_label_unique <- unique(df[[group_label_sym]])
  max_y <- max(df[[y_var_sym]])
  caption <- ifelse(
    caption[1] == "",
    "",
    paste(
      caption_prefix,
      caption[1]
    )
  )

  # Determine required number of discrete colors and get appropriate palette
  colors_n <- dplyr::n_distinct(df[[group_var_sym]])

  # Set facet element
  if(!has_facet)  {
    facet <- NULL
  } else {
    facet <- ggplot2::facet_wrap(
      ggplot2::vars(
        !!facet_var_quo
      )
 #     ,ncol = 1
    )
  }

  df_label <- dplyr::filter(
    df,
    {{y_var}} >= filter_cutoff
    )

  ggplot2::ggplot(
    data = df,
    ggplot2::aes(
      x = {{x_var}},
      y = {{y_var}},
      group = {{group_var}},
      color = {{group_var}},
      label = {{y_var}}
    )
  ) +
    ggplot2::geom_line(
      stat = "identity",
      size = 1
    ) +
    ggplot2::geom_label(
      data = df_label,
      size = base_size / 5,
      family = base_family,
      colour = color,
      fill = "white",
      show.legend = FALSE,
      label.r = ggplot2::unit(0, "lines"),
      label.padding = ggplot2::unit(0.10, "lines")
    ) +
    facet +
    scale_color_rub(
      palette = "discrete",
      discrete = TRUE,
      name = NULL,
      labels = group_label_unique,
      colors_n
    ) +
    ggplot2::scale_y_continuous(
      expand = c(0, 0),
      labels = function(y_var)
        format(
          {{y_var}},
          big.mark = ".",
          decimal.mark = ",",
          scientific = FALSE
        ),
      limits = c(0, max_y) * 1.1
    ) +
    ggplot2::labs(
      caption = caption,
      x = x_axis_label[1],
      y = y_axis_label[1]
      ) +
    theme_rub(
      base_family = base_family,
      base_size = base_size,
      color = color,
      has_facet = has_facet,
      x_axis_label = has_x_axis_label,
      y_axis_label = has_y_axis_label
      )
}


#' Plot grouped line chart on top of vertical stacked bar chart (figure type 5)
#'
#' @inheritParams rub_plot_type_1
#' @inheritParams rub_plot_type_4
#' @inheritParams theme_rub
#'
#' @return A ggplot object
#' @export
#'
#' @examples
#' rub_plot_type_1_and_4(df = df)
rub_plot_type_1_and_4 <- function(df, x_var, x_axis_label = "",
                                  y_var, y_axis_label = "",
                                  fill_var, fill_reverse = FALSE,
                                  fill_label = NULL,
                                  group_var, group_label = NULL,
                                  caption = "", caption_prefix = "Quelle:",
                                  filter_cutoff = 0.04, facet_var = NULL,
                                  color = RUB_colors["blue"],
                                  base_family = "RubFlama",
                                  base_size = 11)  {
  plot_t1 <- df %>%
    dplyr::filter(
      figure_type_id == 1L
      ) %>%
    rub_plot_type_1(
      x_var = {{x_var}},
      y_var = {{y_var}},
      y_axis_label = y_axis_label,
      fill_var = {{fill_var}},
      fill_reverse = fill_reverse,
      fill_label ={{fill_label}},
      caption = caption,
      caption_prefix = caption_prefix,
      filter_cutoff = filter_cutoff,
      facet_var = {{facet_var}},
      color = color,
      base_family = base_family,
      base_size = base_size
      )

  plot_t4_additions <- df %>%
    dplyr::filter(
      figure_type_id == 4L
      ) %>%
    add_rub_plot_type_4(
      x_var = {{x_var}},
      y_var = {{y_var}},
      group_var = {{group_var}},
      group_label = {{group_label}},
      base_size = base_size,
      base_family = base_family,
      color = RUB_colors["blue"]
    )

  plot_t1_t4 <- plot_t1 +
    rlang::eval_tidy(
      plot_t4_additions[[1]]
      ) +
    rlang::eval_tidy(
      plot_t4_additions[[2]]
      ) +
    rlang::eval_tidy(
      plot_t4_additions[[3]]
      ) +
    rlang::eval_tidy(
      plot_t4_additions[[4]]
      )

  return(plot_t1_t4)
}

#' Helper Function
#' @param df_t4 Data frame
#' @inheritParams rub_plot_type_1_and_4
#'
#' @return List of ggplot2 expressions
#' @export
#'
#' @examples
#' add_rub_plot_type_4(df, x, y, group, group_label)
add_rub_plot_type_4 <- function(df_t4, x_var,
                               y_var, group_var,
                               group_label = NULL, base_size = 11,
                               base_family = "RubFlama",
                               color = RUB_colors["blue"]) {

  # Defuse R expressions
  group_label_quo <- rlang::enquo(group_label)
  group_var_sym <- rlang::ensym(group_var)

  # Booleans
  has_group_label <- !rlang::quo_is_null(group_label_quo)

  if(has_group_label) {
    group_label_sym <- rlang::ensym(group_label)
  } else  {
    group_label_sym <- rlang::ensym(group_var)
  }

  # Plotting variables
  group_label_unique <- unique(df_t4[[group_label_sym]])
  # Determine required number of discrete colors and get appropriate palette
  colors_n <- dplyr::n_distinct(df_t4[[group_var_sym]])

  expr_list <- vector("list", 4)

  expr_list[[1]] <- rlang::quo(
    ggplot2::geom_line(
      data = df_t4,
      ggplot2::aes(
        x = {{x_var}},
        y = {{y_var}},
        group = {{group_var}},
        color = {{group_var}}
      ),
      stat = "identity",
      size = 1
    #  ,show.legend = FALSE
    )
  )

  expr_list[[2]] <- rlang::quo(
    ggplot2::geom_label(
      data = df_t4,
      ggplot2::aes(
        x = {{x_var}},
        y = {{y_var}},
        group = {{group_var}},
        color = {{group_var}},
        label = {{y_var}}
      ),
      size = base_size / 5,
      family = base_family,
      colour = color,
      fill = "white",
      show.legend = FALSE,
      label.r = ggplot2::unit(0, "lines"),
      label.padding = ggplot2::unit(0.10, "lines")
    )
  )

  expr_list[[3]] <- rlang::quo(
    RUBer::scale_color_rub(
      palette = "discrete_contrast",
      discrete = TRUE,
      name = NULL,
      labels = group_label_unique,
      colors_n
    )
  )

  expr_list[[4]] <- rlang::quo(
    ggplot2::guides(
      fill = ggplot2::guide_legend(
        order = 1,
        reverse = FALSE,
        byrow = TRUE,
        override.aes = list(shape = 24)
        ),
      color = ggplot2::guide_legend(
        order = 2
        )
      )
    )

  return(expr_list)
}
