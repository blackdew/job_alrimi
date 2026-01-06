/**
 * 텍스트에서 전화번호 추출
 * @param {string} text - 검색할 텍스트
 * @returns {string[]} 추출된 전화번호 배열
 */
export function extractPhoneNumbers(text) {
  if (!text) return [];

  // 한국 전화번호 패턴
  const patterns = [
    /\d{2,3}-\d{3,4}-\d{4}/g,      // 055-123-4567, 010-1234-5678
    /\d{2,3}\.\d{3,4}\.\d{4}/g,    // 055.123.4567
    /\(\d{2,3}\)\s?\d{3,4}-\d{4}/g, // (055) 123-4567
    /\d{10,11}/g,                    // 01012345678
  ];

  const phones = new Set();

  for (const pattern of patterns) {
    const matches = text.match(pattern);
    if (matches) {
      matches.forEach(phone => {
        // 정규화: 하이픈 형식으로 통일
        const normalized = normalizePhone(phone);
        if (normalized) phones.add(normalized);
      });
    }
  }

  return Array.from(phones);
}

/**
 * 전화번호 정규화
 * @param {string} phone - 원본 전화번호
 * @returns {string|null} 정규화된 전화번호
 */
function normalizePhone(phone) {
  const digits = phone.replace(/\D/g, '');

  // 휴대폰 (010, 011, 016, 017, 018, 019)
  if (digits.length === 11 && digits.startsWith('01')) {
    return `${digits.slice(0, 3)}-${digits.slice(3, 7)}-${digits.slice(7)}`;
  }

  // 일반 전화 (지역번호 2~3자리)
  if (digits.length === 10) {
    if (digits.startsWith('02')) {
      return `${digits.slice(0, 2)}-${digits.slice(2, 6)}-${digits.slice(6)}`;
    }
    return `${digits.slice(0, 3)}-${digits.slice(3, 6)}-${digits.slice(6)}`;
  }

  if (digits.length === 9 && digits.startsWith('02')) {
    return `${digits.slice(0, 2)}-${digits.slice(2, 5)}-${digits.slice(5)}`;
  }

  return null;
}

/**
 * 텍스트에서 키워드 태깅
 * @param {string} text - 검색할 텍스트
 * @returns {string[]} 매칭된 키워드 배열
 */
export function extractKeywords(text) {
  if (!text) return [];

  const keywords = {
    job: ['구인', '채용', '모집', '일자리', '취업', '알바', '파트타임', '정규직', '계약직'],
    field: ['사무직', '밭일', '농사', '어업', '수산', '관광', '숙박', '요식업', '건설'],
    house: ['빈집', '매매', '임대', '월세', '전세', '촌집', '귀농', '귀촌', '농가주택'],
  };

  const matched = [];
  const lowerText = text.toLowerCase();

  for (const [category, words] of Object.entries(keywords)) {
    for (const word of words) {
      if (lowerText.includes(word)) {
        matched.push(word);
      }
    }
  }

  return [...new Set(matched)];
}
