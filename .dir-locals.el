;;; Directory Local Variables
;;; For more information see (info "(emacs) Directory Variables")

((nil
  (eval local-set-key
		(kbd "M-e")
		'(lambda nil
		   (interactive)
		   (save-buffer)
		   (compile (format "make -C %s" (magit-get-top-dir))))))
 (haskell-mode
  (flycheck-haskell-hlint-executable . "hlint --cpp-define=HLINT=true")))
