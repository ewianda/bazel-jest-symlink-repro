import { useCallback } from 'react'

export const useAppDispatch = () => {
  const dispatch = useCallback((action: unknown) => {
    console.log('dispatched', action)
  }, [])
  return dispatch
}
