## Author: Rajan Topiwala
## Purpose: Extract the graphs used in the presentation and the report so it calls on this script when run. 

forecast_plots <- function(level_series, pchange_series, combined_title, x_start = 1998) {
  # Declare function to create the main plots comparing premium projections
  #' Generate Projection Plots
  #'
  #' Creates combined level and percent change projection plots based on provided series data.
  #'
  #' @param level_series A character vector specifying the series to be plotted as levels.
  #' @param pchange_series A character vector specifying the series to be plotted as percent changes.
  #' @param combined_title A string representing the title for the combined plot.
  #'
  #' @return A combined ggplot object displaying both level and percent change projections.
  
  subplot <- function(subplot_series, is_levels = TRUE) { 
    #' Generate a Subplot for Specified Data Series
    #'
    #' This function creates a ggplot-based subplot for the given data series. It differentiates between historical and projection data by styling historical data as solid lines and projection data as dashed lines. The y-axis can be formatted to display either levels in dollars or percent changes based on the `is_levels` parameter.
    #'
    #' @param subplot_series A character vector specifying the series to include in the subplot.
    #' @param is_levels A logical value indicating whether to format the y-axis as levels (`TRUE`) or percent changes (`FALSE`). Defaults to `TRUE`.
    #'
    #' @return A ggplot object representing the generated subplot.
    
    # Duplicate the dataset, with the series truncated at the last historical year in one copy
    # This allows us to plot the historical data as a solid line and the projection data as a dashed line
    plot_data_full <- df_long %>%
      filter(
        year >= 1998,
        series %in% subplot_series 
      ) |>
      mutate(actual = "Projection")
    plot_data_actual <- plot_data_full %>%
      filter(year <= last_historical_year) |>
      mutate(actual = "Historical")
    plot_data <- bind_rows(
      plot_data_actual,
      plot_data_full
    )
    
    
    # Define the plot
    return_plot <- plot_data |>
      ggplot(aes(x = year, y = value, color = series, shape = series, linetype = actual)) +
      geom_hline(yintercept = 0, color = "grey") +
      geom_vline(xintercept = projection_start, color = "grey", linetype = "dashed") + 
      geom_line(size = 1.2) +
      geom_point(size = 2.5) +
      scale_linetype_manual(values = c("Projection" = "dashed", "Historical" = "solid")) + 
      scale_color_manual(
        values = color_values,
        labels = label_values
      ) + 
      scale_shape_manual(
        values = shape_values,
        labels = label_values
      ) + 
      labs(
        x = NULL,
        color = NULL,
        shape = NULL
      ) +
      guides(linetype = "none")

    x_start = ifelse(is.null(x_start), min(df_long$year, na.rm = TRUE), x_start)
    x_end   <- max(df_long$year, na.rm = TRUE)

    return_plot <- return_plot +
      coord_cartesian(xlim = c(x_start, x_end)) +
      scale_x_continuous(
        breaks = if (x_start >= 2018) seq(x_start, x_end, by = 2) else ggplot2::waiver(),
        expand = expansion(mult = c(0, 0.02))
    )
    
    # Format the y-axis based on whether the series are levels or percent changes
    if (is_levels) {
      return_plot <- return_plot + 
        # Format the y-axis labels as dollars and start the y-axis at 0
        scale_y_continuous(labels = scales::dollar, limits = c(1000, NA)) +
        labs(y = "Dollars")
    }
    else {
      return_plot <- return_plot + 
        # Format the y-axis labels as percentages and start the y-axis at 0
        scale_y_continuous(labels = scales::percent, limits = c(0.01, NA)) +
        labs(y = "Percent Change")
    }
    return(return_plot)
  }
  
  # Generate the plots for the level and percent change series
  level_plot <- subplot(level_series, is_levels = TRUE)
  growth_plot <- subplot(pchange_series, is_levels = FALSE)
  
  # Generate and return the combined plot
  combined_plot <- (level_plot | growth_plot) +
    plot_layout(guides = "collect") &
    plot_annotation(
      title = combined_title
    ) &
    theme(
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
      legend.position = "top",
      legend.title = element_blank(),
      # Set the background of the markers in the legend to be transparent
      legend.key = element_rect(fill = "transparent")
    )
  return(combined_plot)
}