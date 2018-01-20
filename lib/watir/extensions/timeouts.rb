class Selenium::WebDriver::Timeouts
  def implicit_wait=(*)
    Watir.logger.warn "Implicit Waits are not respected by Watir"
  end
end
