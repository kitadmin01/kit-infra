import { fail } from 'k6'

export const ANALYTICKIT_API_ENDPOINT = __ENV.ANALYTICKIT_API_ENDPOINT
export const ANALYTICKIT_EVENT_ENDPOINT = __ENV.ANALYTICKIT_EVENT_ENDPOINT

export function checkPrerequisites() {
  if (!ANALYTICKIT_API_ENDPOINT || !ANALYTICKIT_EVENT_ENDPOINT) {
    fail("Please specify env variables ANALYTICKIT_API_ENDPOINT and ANALYTICKIT_EVENT_ENDPOINT")
  }
}

export const SKIP_SOURCE_IP_ADDRESS_CHECK = __ENV.SKIP_SOURCE_IP_ADDRESS_CHECK
