import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useAppDispatch } from './store'

export const useDeleteItem = () => {
  const queryClient = useQueryClient()
  const dispatch = useAppDispatch()

  return useMutation({
    mutationFn: async (id: string) => {
      return { id }
    },
    onSuccess: () => {
      dispatch({ type: 'DELETED' })
      queryClient.invalidateQueries({ queryKey: ['items'] })
    },
  })
}
