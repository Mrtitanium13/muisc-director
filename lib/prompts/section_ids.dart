/// Prompt section identifiers for the Music Director system prompt.
enum PromptSection {
  section1A('1A', 'section_1a.txt'),
  section1B('1B', 'section_1b.txt'),
  section1C('1C', 'section_1c.txt'),
  section1D('1D', 'section_1d.txt'),
  section1E('1E', 'section_1e.txt'),
  section1F('1F', 'section_1f.txt');

  const PromptSection(this.id, this.fileName);

  final String id;
  final String fileName;
}

/// Ordered list of all sections for consolidated body assembly.
const List<PromptSection> allSections = PromptSection.values;

/// DJ mix bookend tags enforced by Section 1F.
const String djMixInTag = '[Intro: DJ Mix-In]';
const String djMixOutTag = '[Outro: DJ Mix-Out]';
const String endTag = '[End]';
