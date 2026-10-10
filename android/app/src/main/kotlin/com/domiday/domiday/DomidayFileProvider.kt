package com.domiday.domiday

import androidx.core.content.FileProvider

/// Свой подкласс, чтобы не конфликтовать с провайдерами плагинов при
/// слиянии манифестов; пути — в res/xml/share_paths.xml.
class DomidayFileProvider : FileProvider()
